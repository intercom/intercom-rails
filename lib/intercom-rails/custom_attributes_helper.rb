module IntercomRails

  module CustomDataHelper

    # This helper allows custom data attributes to be added to a user
    # for the current request from within the controller. e.g.
    #
    # def destroy
    #   intercom_custom_attributes.user['canceled_at'] = Time.now
    #   ...
    # end
    def intercom_custom_attributes
      @_request_specific_intercom_custom_attributes ||= begin
        s = Struct.new(:user, :company).new
        s.user = {}
        s.company = {}
        s
      end
    end

  end

end
