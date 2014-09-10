class Metadata < ActiveRecord::Base
  include GPSParser
  include PgSearch

  CAMERA_ATTRIBUTES = [
    :make, :model, :serial_number, :camera_type, :lens_type, :lens_model,
    :max_focal_length, :min_focal_length, :max_aperture, :min_aperture,
    :num_af_points, :sensor_width, :sensor_height, :orientation
  ]

  SETTINGS_ATTRIBUTES = [
    :format, :fov, :aperture, :focal_length,
    :shutter_speed, :iso, :exposure_program, :exposure_mode,
    :metering_mode, :flash, :drive_mode, :digital_zoom, :macro_mode,
    :self_timer, :quality, :record_mode, :easy_mode, :contrast,
    :saturation, :sharpness, :focus_range, :auto_iso, :base_iso,
    :measured_ev, :target_aperture, :target_exposure_time, :white_balance,
    :camera_temperature, :flash_guide_number, :flash_exposure_comp,
    :aeb_bracket_value, :focus_distance_upper, :focus_distance_lower,
    :nd_filter, :flash_sync_speed_av, :shutter_curtain_sync, :mirror_lockup,
    :bracket_mode, :bracket_value, :bracket_shot_number, :hyperfocal_distance,
    :circle_of_confusion
  ]

  CREATOR_ATTRIBUTES = [
    :copyright_notice, :rights, :creator, :creator_country, :creator_city
  ]

  IMAGE_ATTRIBUTES = [
    :color_space, :image_width, :image_height, :gps_position, :lat, :lng,
    :flash_output, :gamma, :image_size, :date_created, :date_time_original
  ]

  EDITABLE_KEYS = [
    :id, :title, :description, :keywords, :lat, :lng, :make, :model, :serial_number,
    :camera_type, :lens_type, :lens_model, :copyright_notice
  ]

  belongs_to :photograph, touch: true
  has_one :user, through: :photograph

  store_accessor :image, :lat
  store_accessor :image, :lng
  store_accessor :image, :format

  store_accessor :camera, [
    :make, :model, :serial_number, :camera_type, :lens_type, :lens_model
  ]

  store_accessor :creator, [
    :copyright_notice
  ]

  validates :photograph_id, presence: true

  pg_search_scope :fulltext_search,
                  against: [:title, :description],
                  using: {
                    tsearch: { 
                      dictionary: 'english',
                      tsvector_column: 'search_vector'
                    }
                  }

  scope :with_keyword, -> (keyword) {
    with_keywords([keyword])
  }

  scope :with_keywords, -> (keywords) {
    keywords = keywords.map { |kw| Metadata.clean_keyword(kw) }.join(",")
    where("metadata.keywords @> ?", "{#{keywords}}")
  }
  
  scope :format, -> (format) {
    where("metadata.image @> 'format=>#{format}'")
  }

  before_create :set_defaults
  def set_defaults
    self.processing = true
    self.camera ||= {}
    self.settings ||= {}
    self.creator ||= {}
    self.image ||= {}
  end

  def extract_from_photograph
    begin
      Metadata.benchmark "Extracting EXIF" do
        exif = photograph.exif

        self.title        = fetch_title(exif) if raw_title.blank?
        self.description  = exif.description if description.blank?
        self.keywords     = exif.keywords if keywords.blank?

        self.camera = fetch_from_exif(exif, CAMERA_ATTRIBUTES)
        self.settings = fetch_from_exif(exif, SETTINGS_ATTRIBUTES)
        self.creator = fetch_from_exif(exif, CREATOR_ATTRIBUTES)
        self.image = fetch_from_exif(exif, IMAGE_ATTRIBUTES)
      end

      convert_lat_lng
      set_format

      self.processing = false
      return true
    rescue ArgumentError => ex
      # Prevent UTF-8 bug from stopping photo upload
      self.camera ||= {}
      self.settings ||= {}
      self.creator ||= {}
      self.image ||= {}
    end
  end

  def fetch_title(exif)
    [:title, :caption, :subject].map { |a| 
      exif.send(a)
    }.keep_if(&:present?).keep_if { |v| v.is_a?(String) }.first
  end

  def convert_lat_lng
    gps_position = image['gps_position'] || image[:gps_position]
    if gps_position.present?
      self.lat, self.lng = convert_to_lat_lng(gps_position)      
    end
  end
  
  def set_format
    width = image['image_width'] || image[:image_width]
    height = image['image_height'] || image[:image_height]
    
    if height.nil? || width.nil?
      self.format = 'unknown'
    elsif height > width
      self.format = 'portrait'
    elsif height == width
      self.format = 'square'
    else
      self.format = 'landscape'
    end
  end

  def raw_title
    read_attribute(:title)
  end

  def title
    title = raw_title
    title.blank? ? I18n.t("untitled") : title
  end

  def keywords=(value)
    if value.is_a?(String)
      value = value.split(",").map(&:strip)
    end

    super(value)
  end

  def keywords
    (super || []).map { |kw| kw.to_s.force_encoding("utf-8") }
  end

  def keywords_string
    keywords.join(", ") unless keywords.nil?
  end

  def has_text?
    title.present? || description.present?
  end
  
  def has_location_data?
    lat.present? && lng.present?
  end

  def landscape?
    format == 'landscape'
  end

  def portrait?
    format == 'portrait'
  end

  def square?
    format == 'square'
  end

  def rotate?
    rotate_by.present? && (rotate_by < 0 || rotate_by > 0)
  end

  def rotate_by
    if camera.present? && camera['orientation'].present?
      match = camera['orientation'].match(/Rotate (\d+) (CW|CCW)/)

      if match
        degrees = match[1]
        direction = match[2]

        direction == "CCW" ? "-#{degrees}".to_i : degrees.to_i
      end
    end
  end

  def can_edit?(key)
    self.respond_to?("#{key}=") && EDITABLE_KEYS.include?(key.to_sym)
  end

  class << self
    def clean_keyword(word)
      ActiveRecord::Base.sanitize(word).gsub("\"", "")
    end
  end


  private
  def fetch_from_exif(exif, keys = [])
    Rails.logger.debug "Fetching EXIF"
    return_hash = {}

    exif.to_hash.each do |key, value|
      next if key.nil?

      key = key.underscore.to_sym
      if keys.include?(key)
        return_hash[key] = value
      end
    end

    return_hash
  end
end
