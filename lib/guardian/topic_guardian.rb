#mixin for all guardian methods dealing with topic permisions
module TopicGuardian

  def can_remove_allowed_users?(topic)
    is_staff?
  end

  # Creating Methods
  def can_create_topic?(parent)
    is_staff? ||
    (user &&
      user.trust_level >= SiteSetting.min_trust_to_create_topic.to_i &&
      can_create_post?(parent))
  end

  def can_create_topic_on_category?(category)
    can_create_topic?(nil) &&
    (!category || Category.topic_create_allowed(self).where(:id => category.id).count == 1)
  end

  def can_create_post_on_topic?(topic)
    # No users can create posts on deleted topics
    return false if topic.trashed?

    is_staff? || (authenticated? && user.has_trust_level?(:elder)) || (not(topic.closed? || topic.archived? || topic.trashed?) && can_create_post?(topic))
  end

  # Editing Method
  def can_edit_topic?(topic)
    return false if topic.archived
    return true if is_my_own?(topic)
    return false if Discourse.static_doc_topic_ids.include?(topic.id) && !is_admin?
    is_staff? || user.has_trust_level?(:leader)
  end

  # Recovery Method
  def can_recover_topic?(topic)
    is_staff?
  end

  def can_delete_topic?(topic)
    !topic.trashed? &&
    is_staff? &&
    !(Category.exists?(topic_id: topic.id))
  end

  def can_reply_as_new_topic?(topic)
    authenticated? && topic && not(topic.private_message?) && @user.has_trust_level?(:basic)
  end

  def can_see_deleted_topics?
    is_staff?
  end

  def can_see_topic?(topic)
    return false unless topic
    # Admins can see everything
    return true if is_admin?
    # Deleted topics
    return false if topic.deleted_at && !can_see_deleted_topics?

    # not secure, or I can see it
    (not(topic.read_restricted_category?) || can_see_category?(topic.category)) &&
    # not private, or I am allowed (or is staff)
    (not(topic.private_message?) || (authenticated? && (is_admin? || topic.all_allowed_users.where(id: @user.id).exists?)))

  end
end
