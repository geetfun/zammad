# encoding: utf-8
require 'test_helper'

class AutoWizardTest < ActiveSupport::TestCase

  test 'simple' do
    auto_wizard_data = {
      Users: [
        {
          login: 'master_unit_test01@example.com',
          firstname: 'Test Master',
          lastname: 'Agent',
          email: 'master_unit_test01@example.com',
          password: 'test',
        },
        {
          login: 'agent1_unit_test01@example.com',
          firstname: 'Agent 1',
          lastname: 'Test',
          email: 'agent1_unit_test01@example.com',
          password: 'test',
          roles: ['Agent'],
        }
      ],
      Groups: [
        {
          name: 'some group1',
          users: ['master_unit_test01@example.com', 'agent1_unit_test01@example.com']
        }
      ],
      Settings: [
        {
          name: 'developer_mode',
          value: true
        },
        {
          name: 'product_name',
          value: 'Zammad UnitTest01 System'
        },
      ]
    }
    assert_equal(false, AutoWizard.enabled?)
    auto_wizard_file_write(auto_wizard_data)
    assert_equal(true, AutoWizard.enabled?)
    AutoWizard.setup
    assert_equal(false, AutoWizard.enabled?)

    # check first user roles
    auto_wizard_data[:Users][0][:roles] = %w(Agent Admin)

    auto_wizard_data[:Users].each {|local_user|
      user = User.find_by(login: local_user[:login])
      assert_equal(local_user[:login], user.login)
      assert_equal(local_user[:firstname], user.firstname)
      assert_equal(local_user[:lastname], user.lastname)
      assert_equal(local_user[:email], user.email)
      assert_equal(local_user[:roles].count, user.role_ids.count)
      next unless local_user[:roles]
      local_user[:roles].each {|local_role_name|
        local_role = Role.find_by(name: local_role_name)
        assert(user.role_ids.include?(local_role.id))
      }
    }
    auto_wizard_data[:Groups].each {|local_group|
      group = Group.find_by(name: local_group[:name])
      assert_equal(local_group[:name], group.name)
      next unless local_group[:users]
      local_group[:users].each {|local_user_login|
        local_user = User.find_by(login: local_user_login)
        assert(group.user_ids.include?(local_user.id))
      }
    }
    auto_wizard_data[:Settings].each {|local_setting|
      setting_value = Setting.get(local_setting[:name])
      assert_equal(local_setting[:value], setting_value)
    }
  end

  test 'complex' do
    auto_wizard_data = {
      Organizations: [
        {
          name: 'Auto Wizard Test Org',
          shared: false,
        }
      ],
      Users: [
        {
          login: 'master_unit_test01@example.com',
          firstname: 'Test Master',
          lastname: 'Agent',
          email: 'master_unit_test01@example.com',
          password: 'test',
          organization: 'Auto Wizard Test Org',
          roles: ['Admin'],
        },
        {
          login: 'agent1_unit_test01@example.com',
          firstname: 'Agent 1',
          lastname: 'Test',
          email: 'agent1_unit_test01@example.com',
          password: 'test',
          roles: ['Agent'],
        }
      ],
      Groups: [
        {
          name: 'some group1',
          users: ['master_unit_test01@example.com', 'agent1_unit_test01@example.com']
        }
      ],
      Settings: [
        {
          name: 'developer_mode',
          value: false,
        },
        {
          name: 'product_name',
          value: 'Zammad UnitTest02 System'
        },
      ]
    }
    assert_equal(false, AutoWizard.enabled?)
    auto_wizard_file_write(auto_wizard_data)
    assert_equal(true, AutoWizard.enabled?)
    AutoWizard.setup
    assert_equal(false, AutoWizard.enabled?)

    auto_wizard_data[:Users].each {|local_user|
      user = User.find_by(login: local_user[:login])
      assert_equal(local_user[:login], user.login)
      assert_equal(local_user[:firstname], user.firstname)
      assert_equal(local_user[:lastname], user.lastname)
      assert_equal(local_user[:email], user.email)
      next unless local_user[:roles]
      assert_equal(local_user[:roles].count, user.role_ids.count)
      local_user[:roles].each {|local_role_name|
        local_role = Role.find_by(name: local_role_name)
        assert(user.role_ids.include?(local_role.id))
      }
    }
    auto_wizard_data[:Groups].each {|local_group|
      group = Group.find_by(name: local_group[:name])
      assert_equal(local_group[:name], group.name)
      next unless local_group[:users]
      local_group[:users].each {|local_user_login|
        local_user = User.find_by(login: local_user_login)
        assert(group.user_ids.include?(local_user.id))
      }
    }
    auto_wizard_data[:Settings].each {|local_setting|
      setting_value = Setting.get(local_setting[:name])
      assert_equal(local_setting[:value], setting_value)
    }
  end

  def auto_wizard_file_write(data)
    location = "#{Rails.root}/auto_wizard.json"
    file = File.new(location, 'wb')
    file.write(data.to_json)
    file.close
  end

  def auto_wizard_file_exists?
    location = "#{Rails.root}/auto_wizard.json"
    return false if File.exist?(location)
    true
  end

end
