module IntercomRails

  module CustomDataHelper

    # This helper allows custom data attributes to be added to a user
    # for the current request from within the controller. e.g.
    #
    # def destroy
    #   intercom_custom_data.user['canceled_at'] = Time.now
    #   ...
    # end
    def intercom_custom_data
      @_request_specific_intercom_custom_data ||= begin
        s = Struct.new(:user, :company).new
        s.user = {}
        s.company = {}
        s
      end
    end

    def hide_intercom_messenger_for_request(hide = true)
      @hide_intercom_messenger = hide
    end

    def hide_intercom_messenger_for_request?
      @hide_intercom_messenger == true
    end
  end

end
