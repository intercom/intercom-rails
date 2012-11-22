module IntercomRails

  class CurrentUserNotFoundError < StandardError; end

  class CurrentUser

    POTENTIAL_USER_OBJECTS = [
      Proc.new { instance_eval &IntercomRails.config.current_user if IntercomRails.config.current_user.present? },
      Proc.new { current_user },
      Proc.new { @user }
    ]

    def self.locate_and_prepare_for_intercom(controller)
      new(controller).to_hash
    end

    attr_reader :controller, :user

    def initialize(controller)
      @controller = controller
      @user = find_user
    end

    def find_user
      POTENTIAL_USER_OBJECTS.each do |potential_user|
        begin
          user = controller.instance_eval &potential_user
          return user if user.present? && 
                         (user.email.present? || user.id.present?)
        rescue NameError
          next
        end
      end

#      raise CurrentUserNotFoundError
    end

    def to_hash
      hsh = {}
      hsh[:user_id] = user.id if attribute_present?(:id) 
      [:email, :name, :created_at].each do |attribute|
        hsh[attribute] = user.send(attribute) if attribute_present?(attribute)
      end

      hsh
    end

    private
    def attribute_present?(attribute)
      user.respond_to?(attribute) && user.send(attribute).present?
    end

  end

end
