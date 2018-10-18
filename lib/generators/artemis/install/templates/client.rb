<% module_namespacing do -%>
class <%= class_name %> < Artemis::Client
  # If an access token needs to be assigned to every request:
  # self.default_context = {
  #   headers: {
  #     Authorization: "token ..."
  #   }
  # }
end
<% end %>