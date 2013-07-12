require 'travis/model/user/renaming'

module Travis
  module Github
    module Services
      class FindOrCreateUser < Travis::Services::Base
        register :github_find_or_create_user

        def run
          find || create
        end

        private

          include ::User::Renaming

          def find
            ::User.where(github_id: params[:github_id]).first.tap do |user|
              if user
                ActiveRecord::Base.transaction do
                  login = params[:login] || data['login']
                  if user.login != login
                    rename_repos_owner(user.login, login)
                    user.update_attributes(login: login)
                  end
                end

                nullify_logins(user.github_id, user.login)
              end
            end
          end

          def create
            user = User.create!(
              :name => data['name'],
              :login => data['login'],
              :email => data['email'],
              :github_id => data['id'],
              :gravatar_id => data['gravatar_id']
            )

            nullify_logins(user.github_id, user.login)

            user
          end

          def data
            @data ||= fetch_data
          end

          def fetch_data
            GH["user/#{params[:github_id]}"] || raise(Travis::GithubApiError)
          end
      end
    end
  end
end
