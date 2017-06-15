require 'spec_helper'

describe IntercomRails::EncryptedMode do
  it 'whitelists certain attributes' do
    encrypted_mode = IntercomRails::EncryptedMode.new("foo", nil, {:enabled => true})
    expect(encrypted_mode.plaintext_part({:app_id => "bar", :baz => "bang"})).to eq({:app_id => "bar"})
  end

  it "encrypts correctly" do
    encrypted_mode = IntercomRails::EncryptedMode.new("foo", "a"*12, {:enabled => true})
    encrypted = encrypted_mode.encrypt({"baz" => "bang"})

    decoded = Base64.decode64(encrypted)

    cipher = OpenSSL::Cipher.new('aes-256-gcm')
    cipher.decrypt
    cipher.key = Digest::SHA256.digest("foo")
    cipher.iv = decoded[0, 12]
    auth_tag_index = decoded.length - 16
    cipher.auth_tag = decoded[auth_tag_index, 16]
    ciphertext = decoded[12, decoded.length - 16 - 12]
    result = cipher.update(ciphertext) + cipher.final

    original = JSON.parse(result)
    expect(original).to eq({"baz" => "bang"})
  end
end
