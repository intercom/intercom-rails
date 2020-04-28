module IntercomRails

  module CustomDataHelper
    STORE = Struct.new(:user, :company)

    # This helper allows custom data attributes to be added to a user
    # for the current request from within the controller. e.g.
    #
    # def destroy
    #   intercom_custom_data.user['canceled_at'] = Time.now
    #   ...
    # end
    def intercom_custom_data
      @_request_specific_intercom_custom_data ||= STORE.new({}, {})
    end

  end

end
