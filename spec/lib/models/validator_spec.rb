require 'ostruct'
require 'models/interceptor/validator'

class Post; end

describe Interceptor::Validator do
  describe "wraps post" do
    let(:attributes) {
      {
      :created_by => 1,
      :realm => 'realm',
      :uid => 'uid',
      :tags => %w(a b c),
      :document => {
      :paths => 'x,y,z',
      :url => 'url'
    }
    }
    }
    let(:post) { OpenStruct.new(attributes) }

    let(:interceptor) { Interceptor::Validator.new(post) }
    subject { interceptor }

    its(:klasses_and_actions) { should eq(%w(a b c)) }
    its(:paths) { should eq(%w(x y z)) }
    its(:url) { should eq('url') }
    its(:realm) { should eq('realm') }
    its(:uid) { should eq('uid') }

    describe "additional attributes" do
      subject do
        interceptor.with(:action => 'singing', :session => 'abc', :identity => stub(:id => 42))
      end

      its(:action) { should eq('singing') }
      its(:session) { should eq('abc') }
      its(:identity_id) { should eq(42) }
    end
  end
end
