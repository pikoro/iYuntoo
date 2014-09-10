$(document).ready ->
  photoForm = $("form#photograph-uploader")
  if photoForm.length > 0
    photoForm.S3Uploader
      progress_bar_target: photoForm.parent().find(".bars")
      before_add: (file) ->
        file.type == "image/jpeg"

    photoForm.bind "s3_uploads_start", (e) ->
      window.onbeforeunload = ->
        I18n.t("account.photographs.exit")

    photoForm.bind "s3_uploads_complete", (e) ->
      window.onbeforeunload = null

    photoForm.bind "ajax:success", (e, data) ->
      $(".photo-grid").prepend(data).find("img").load ->
        $(".photo-grid").trigger("reload:grid")

    photoForm.bind "ajax:failure", (e, data) ->
      alert(data)

  massEditForm = $("form#new_mass_edit")
  if massEditForm.length > 0
    massEditForm.data('edit-mode', false)

    massEditForm.find("li.photo input[type = 'checkbox']").prop("checked", false)

    massEditForm.on "click", "#toggle-edit-mode", (e) ->
      e.preventDefault()
      e.stopPropagation()

      $(this).toggleClass("alert")
      $(this).parents(".sub-nav").find(".button").not(this).toggleClass("disabled")
      massEditForm.toggleClass("edit-mode")
      massEditForm.data('edit_mode', !(massEditForm.data('edit_mode')))

    massEditForm.on "click", "[data-action]", (e) ->
      action = $(this).data('action')
      console.log action
      massEditForm.prepend("<input type='hidden' name='mass_edit[action]' value='#{action}'>")

    massEditForm.on "click", ".button.disabled", (e) ->
      e.preventDefault()
      e.stopPropagation()

    massEditForm.on "click", "li.photo", (e) ->
      if massEditForm.data('edit_mode')
        e.preventDefault()
        e.stopPropagation()
        
        li = $(this)
        checkbox = li.find("input[type = 'checkbox']")
        if checkbox.prop("checked")
          checkbox.prop("checked", false)
          li.removeClass("active")
        else
          checkbox.prop("checked", true)
          li.addClass("active")

