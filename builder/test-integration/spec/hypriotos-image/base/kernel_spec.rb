require 'spec_helper'

describe command('uname -r') do
  its(:stdout) { should match /3.10.104-186/ }
  its(:exit_status) { should eq 0 }
end
