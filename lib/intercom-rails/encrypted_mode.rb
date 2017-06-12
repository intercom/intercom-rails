module IntercomRails
  class EncryptedMode
    attr_reader :secret, :initialization_vector, :enabled

    ENCRYPTED_MODE_SETTINGS_WHITELIST = [:app_id, :session_duration, :widget, :custom_launcher_selector, :hide_default_launcher, :alignment, :horizontal_padding, :vertical_padding]

    def initialize(secret, initialization_vector, options)
      @secret = secret
      @initialization_vector = initialization_vector || SecureRandom.random_bytes(12)
      @enabled = options.fetch(:enabled, false)
    end

    def plaintext_part(settings)
      enabled ? settings.slice(*ENCRYPTED_MODE_SETTINGS_WHITELIST) : settings
    end

    def encrypted_javascript(payload)
      enabled ? "window.intercomEncryptedPayload = \"#{encrypt(payload)}\";" : ""
    end

    def encrypt(payload)
      return nil unless enabled
      payload = payload.except(*ENCRYPTED_MODE_SETTINGS_WHITELIST)
      key = Digest::SHA256.digest(secret)
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.encrypt
      cipher.key = key
      cipher.iv = initialization_vector
      json = ActiveSupport::JSON.encode(payload).gsub('<', '\u003C')
      encrypted = initialization_vector + cipher.update(json) + cipher.final + cipher.auth_tag
      Base64.encode64(encrypted).gsub("\n", "\\n")
    end
  end
end
