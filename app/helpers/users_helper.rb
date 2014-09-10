module UsersHelper
  def follow_user_button(user, size_classes = "tiny expand")
    if user_signed_in? && user != current_user
      if current_user.following?(user)
        following = current_user.follower_followings.find_by(followee_id: user.id)
        link_to following_path(following), method: :delete, class: "button unfollow alert #{size_classes}" do
          t("followings.unfollow")
        end
      else
        link_to user_followings_path(user.username), method: :post, class: "button follow secondary #{size_classes}" do
          t("followings.follow")
        end
      end
    end
  end
end
