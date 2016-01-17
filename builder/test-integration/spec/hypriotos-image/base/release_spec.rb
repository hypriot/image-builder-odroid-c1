require 'spec_helper'

describe file('/etc/os-release') do
  it { should be_file }
  it { should be_owned_by 'root' }
  its(:content) { should match 'HYPRIOT_OS=' }
  its(:content) { should match 'HYPRIOT_TAG=' }
  its(:content) { should match 'HYPRIOT_DEVICE=' }

  its(:content) { should match 'HypriotOS/armhf' }
  its(:content) { should match 'ODROID C1/C1+' }
end
