# IntercomRails

The easiest way to install Intercom in a rails app.

For interacting with the Intercom REST API, use the `intercom` gem (https://github.com/intercom/intercom-ruby)

Requires Ruby 2.0 or higher.

## Installation
Add this to your Gemfile:

```ruby
gem "intercom-rails"
```

Then run:

```
bundle install
```

Take note of your `app_id` from [here](https://app.intercom.com/a/apps/_/settings/web) and generate a config file:

```
rails generate intercom:config YOUR-APP-ID
```

To make installing Intercom easy, where possible a `<script>` tag **will be automatically inserted before the closing `</body>` tag**. For most Rails apps, **you won't need to do any extra config**. Having trouble? Check out troubleshooting below.


### Live Chat
With the Intercom Messenger you can [chat](https://www.intercom.com/live-chat) with users and visitors to your web site. Include the Intercom Messenger on every page by setting:
```ruby
  config.include_for_logged_out_users = true
```

### Disabling automatic insertion

To disable automatic insertion for a particular controller or action you can:

```ruby
  skip_after_action :intercom_rails_auto_include
```

### Troubleshooting
If things are not working make sure that:

* You've generated a config file with your `app_id` as detailed above.
* Your user object responds to an `id` or `email` method.
* Your current user is accessible in your controllers as `current_user` or `@user`, if not in `config/initializers/intercom.rb`:
```ruby
  config.user.current = Proc.new { current_user_object }
```
If your users can be defined in different ways in your app you can also pass an array as follows:
```ruby
  config.user.current = [Proc.new { current_user_object }, Proc.new { @user_object }]
```
* If you want the Intercom Messenger to be available when there is no current user,  set `config.include_for_logged_out_users = true` in your config.

Feel free to mail us: team@intercom.io, if you're still having trouble and we'll work with you to get you sorted.

## Configuration

### API Secret
It is possible to enable Identity Verification for the Intercom Messenger and you can find the documentation in how to do it [here](https://developers.intercom.com/docs/enable-secure-mode-on-your-web-product). We strongly encourage doing this as it makes your installation more secure! If you want to use this feature, ensure you set your Identity Verification Secret as the API secret in `config/initializers/intercom.rb`:

```ruby
  config.api_secret = '123456'
```
**Note: This example is just for the sake of simplicity, you should never include this secret in source control. Instead, you should use the Rails [secret config](http://guides.rubyonrails.org/4_1_release_notes.html#config-secrets-yml) feature.**

### Shutdown
We make use of first-party cookies so that we can identify your users the next time they open your messenger. When people share devices with someone else, they might be able to see the most recently logged in user’s conversation history until the cookie expires. Because of this, it’s very important to properly shutdown Intercom when a user’s session on your app ends (either manually or due to an automated logout).

#### Using Devise

If you use devise, you can override (if not already done) the session_controller by replacing in your `config/routes.rb` file:
```ruby
devise_for :users
```
with
```ruby
devise_for :users, controllers: { sessions: "sessions" }
```

Then you can use the following code to prepare Intercom Shutdown on log out in your `app/session_controller.rb`

```ruby
class SessionsController < Devise::SessionsController

  after_action :prepare_intercom_shutdown, only: [:destroy]

  # Your logic here

  protected
  def prepare_intercom_shutdown
    IntercomRails::ShutdownHelper.prepare_intercom_shutdown(session)
  end
end
```

Assuming that the `destroy` method of session_controller redirects to your `visitors_controller.rb#index` method, edit your `visitors_controller` as follow :


```ruby
class VisitorsController < ApplicationController
  after_action :intercom_shutdown, only: [:index]

  def index
    # You logic here
  end

  # You logic here

  protected
  def intercom_shutdown
    IntercomRails::ShutdownHelper.intercom_shutdown(session, cookies, request.domain)
  end
end
```

#### Using another service

If you use another service than Devise or if you implemented your own authentication service, you can call the following method in a controller to shutdown Intercom on logout.

```ruby
IntercomRails::ShutdownHelper::intercom_shutdown_helper(cookies, domain)
```

**Be aware that if you call this method before a 'redirect_to' (quite common on logout) it will have no impact** as it is impossible to update cookies when you use a redirection.
But you can use the same logic as the `devise` implementation above.

#### Session Duration

To add a `session_duration` variable (in ms) to the widget, add the following line to `config/initializers/intercom.rb`:

```ruby
config.session_duration = 5 * 60 * 1000
```
That will force your Intercom session to expire after 5 minutes which is the minimum amount of time authorized.

More information about how session_duration works in [intercom documentation](https://docs.intercom.io/configuring-for-your-product-or-site/customizing-the-intercom-messenger#secure-user-conversations-configure-your-cookie-timeout)

### User Custom data attributes

You can associate any attributes, specific to your app, with a user in Intercom.
For custom data attributes you want updated on every request set them in `config/initializers/intercom.rb`, the latest value will be sent to Intercom on each page visit.

Configure what attributes will be sent using either a:

  * `Proc` which will be passed the current user object
  * Or, a method which will be sent to the current user object

e.g.

```ruby
  config.user.custom_data = {
    :plan => Proc.new { |user| user.plan.name },
    :is_paid => Proc.new { |user| user.plan.present? },
    :email_verified => :email_verified?
  }
  # or If User::custom_data method returns a hash
  config.user.custom_data = Proc.new { |user| user.custom_data }
```

In some situations you'll want to set some custom data attribute specific to a request.
You can do this using the `intercom_custom_data` helper available in your controllers:

```ruby
class AppsController < ActionController::Base
  def activate
    intercom_custom_data.user[:app_activated_at] = Time.now
    ...
  end

  def destroy
    intercom_custom_data.user[:app_deleted_at] = Time.now
    ...
  end
end
```

Attributes must be accessible in order to sync with intercom.
Additionally, attributes ending in "_at" will be parsed as times.

### Custom attributes for non-signed up users

In situations where you want to pass in specific request based custom data for non-signed up users or leads,
you can do that by setting custom attributes in ```config/initializers/intercom.rb```.

Any of these attributes can be used to pass in custom data.

Example:

**in ```config/initializers/intercom.rb```**

```ruby
config.user.lead_attributes = %w(ref_data utm_source)
```

**in ```app/controllers/posts_controller.rb```**

```ruby
class PostsController < ApplicationController

  before_action :set_custom_attributes, only: [:index]

  # Your logic here

  protected
  def set_custom_attributes
    intercom_custom_data.user[:ref_data] = params[:api_ref_data]
    intercom_custom_data.user[:utm_source] = params[:api_utm_source]
  end
end
```

### Companies

By default, Intercom treats all Users as unrelated individuals. If for example you know users are part of a company, you can group them as such.

Read more about it here http://docs.intercom.io/configuring-Intercom/grouping-users-by-company

Basic usage is as follows - in `config/initializers/intercom.rb`

```ruby
config.company.current = Proc.new { current_company }
```

`current_company` is the method/variable that contains the user's current company in your controllers.
If you are using devise you should replace `current_company` with `current_user.company` in the above code and every time you see 'current_company' in your configuration file.
This will result in injecting the user current company in the widget settings.

and like with Users, you can set custom attribute on companies too:

```ruby
config.company.custom_data = {
  :number_of_messages => Proc.new { |app| app.messages.count },
  :is_interesting => :is_interesting?
}
```

### Messenger
Intercom includes an in-app messenger which allows a user to read messages and start conversations.

By default Intercom will add a button that opens the messenger to the page. If you want to customize the style of the link that opens the messenger:

```ruby
  config.inbox.style = :custom
```

With this option enabled, clicks on any element with an id of `Intercom` will open the messenger. So the simplest option here would be to add something like the following to your layout:

```html
  <a id="Intercom">Support</a>
```

You can customize the CSS selector, by setting

```ruby
  config.inbox.custom_activator = '.intercom-link'
```

You can hide default launcher button, by setting

```ruby
  config.hide_default_launcher = true
```

You can read more about configuring the messenger in your applications settings, within Intercom.

### Environments

By default Intercom will be automatically inserted in development and production Rails environments. If you would like to specify the environments in which Intercom should be inserted, you can do so as follows:

```ruby
  config.enabled_environments = ["production"]
```

### Manually Inserting the Intercom Javascript

Some situations may require manually inserting the Intercom script tag. If you simply wish to place the Intercom javascript in a different place within the page or, on a page without a closing `</body>` tag:

```erb
  <%= intercom_script_tag %>
```

This will behave exactly the same as the default auto-install. If for whatever reason you can't use auto-install, you can also provide a hash of user data as the first argument:

```erb
<% if logged_in? %>
  <%= intercom_script_tag({
    :app_id => 'your-app-id',
    :user_id => current_user.id,
    :email => current_user.email,
    :name => current_user.name,
    :created_at => current_user.created_at,
    :custom_data => {
      'plan' => current_user.plan.name
    }
  }) %>
<% end %>
```

You can also override `IntercomRails::Config` options such as your `api_secret`, or widget configuration with a second hash:

```erb
<% if logged_in? %>
  <%= intercom_script_tag({
    :app_id => 'your-app-id',
    :user_id => current_user.id,
    :email => current_user.email,
    :name => current_user.name,
    :created_at => current_user.created_at
  }, {
    :secret => 'your-apps-api-secret',
    :widget => {:activator => '#Intercom'}
  }) %>
<% end %>
```
### Content Security Policy Level 2 (CSP) support
As of version 0.2.30 this gem supports CSP, allowing you to whitelist the include code using both nonces and SHA-256 hashes.
#### Automatic Insertion
CSP support for automatic insertion exposes two namespaces that can be defined by the user via monkey patching:
 - String CoreExtensions::IntercomRails::AutoInclude.csp_nonce_hook(controller)
 - nil CoreExtensions::IntercomRails::AutoInclude.csp_sha256_hook(controller, SHA-256 whitelist entry)

For instance, a CSP nonce can be inserted using the [Twitter Secure Headers](https://github.com/twitter/secureheaders) gem with the following code:
```ruby
module CoreExtensions
  module IntercomRails
    module AutoInclude
      def self.csp_nonce_hook(controller)
        SecureHeaders.content_security_policy_script_nonce(controller.request)
      end
    end
  end
end
```
or, for whitelisting the SHA-256 hash:
```ruby
module CoreExtensions
  module IntercomRails
    module AutoInclude
      def self.csp_sha256_hook(controller, sha256)
        SecureHeaders.append_content_security_policy_directives(controller.request, {script_src: [sha256]})
      end
    end
  end
end
```
#### Manual Insertion
CSP is supported in manual insertion as well, the request nonce can be passed as an option:
```erb
<% if logged_in? %>
  <%= intercom_script_tag({
    :app_id => 'your-app-id',
    :user_id => current_user.id,
    :email => current_user.email,
    :name => current_user.name,
    :created_at => current_user.created_at
  }, {
    :secret => 'your-apps-api-secret',
    :widget => {:activator => '#Intercom'},
    :nonce => get_nonce_from_your_csp_framework
  }) %>
<% end %>
```
The SHA-256 hash is available using `csp_sha256` just after generating the tag itself:
```erb
<%= intercom_script_tag %>
<% add_entry_to_csp_whitelist(intercom_script_tag.csp_sha256) %>
```

## Deleting your users
If you delete a user from your system, you should also delete them from Intercom lest they still receive messages.

You can do this using the [intercom-ruby](https://github.com/intercom/intercom-ruby) gem. In the example below we're using an ActiveJob to perform the delete in the background.

```
class User
  after_destroy { DeleteFromIntercomJob.perform_later(self) }
end

class DeleteFromIntercomJob < ApplicationJob
  def perform(user)
    intercom = Intercom::Client.new
    user = intercom.users.find(id: user.id)
    deleted_user = intercom.users.delete(user)
  end
end
```

## Running tests/specs

specs should run on a clean clone of this repo, using the following commands. (developed against ruby 2.1.2 and 1.9.3)

```
bundle install
bundle exec rake spec
or
bundle exec rspec spec/
```


## Pull Requests

- **Add tests!** Your patch won't be accepted if it doesn't have tests.

- **Document any change in behaviour**. Make sure the README and any other
  relevant documentation are kept up-to-date.

- **Create topic branches**. Don't ask us to pull from your master branch.

- **One pull request per feature**. If you want to do more than one thing, send
  multiple pull requests.

- **Send coherent history**. Make sure each individual commit in your pull
  request is meaningful. If you had to make multiple intermediate commits while
  developing, please squash them before sending them to us.


## Contributors

- Dr Nic Williams (@drnic) - provided a rails generator for adding the Intercom javascript tag into your layout.
- Alexander Chaychuk (@sashich) - fixed bug in user detection when users not persisted (e.g. new session view with devise).

## License

intercom-rails is released under the [MIT License](http://www.opensource.org/licenses/MIT).

## Copyright

Copyright (c) 2011-2020 Intercom, Inc.  All rights reserved.
