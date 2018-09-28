require 'spec_helper'

Artemis::GraphQLEndpoint.register!(:metaphysics, url: 'https://metaphysics-staging.artsy.net')
Artemis::GraphQLEndpoint.lookup(:metaphysics).load_schema!