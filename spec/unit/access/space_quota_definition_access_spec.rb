require 'spec_helper'

module VCAP::CloudController
  RSpec.describe SpaceQuotaDefinitionAccess, type: :access do
    subject(:access) { SpaceQuotaDefinitionAccess.new(Security::AccessContext.new) }
    let(:user) { FactoryBot.create(:user) }
    let(:org) { FactoryBot.create(:organization) }
    let(:scopes) { nil }
    let(:space) { FactoryBot.create(:space, organization: org) }
    let(:object) { FactoryBot.create(:space_quota_definition, organization: org) }

    before { set_current_user(user, scopes: scopes) }

    it_behaves_like :admin_full_access
    it_behaves_like :admin_read_only_access
    it_behaves_like :global_auditor_access

    context 'organization manager' do
      before { org.add_manager(user) }
      it_behaves_like :full_access

      context 'when the organization is suspended' do
        let(:org) { FactoryBot.create(:organization, status: 'suspended') }

        it_behaves_like :read_only_access
      end
    end

    context 'when it is not applied to the space' do
      context 'space manager' do
        before do
          org.add_user(user)
          space.add_manager(user)
        end

        it_behaves_like :no_access
      end

      context 'space developer' do
        before do
          org.add_user(user)
          space.add_developer(user)
        end

        it_behaves_like :no_access
      end

      context 'space auditor' do
        before do
          org.add_user(user)
          space.add_auditor(user)
        end

        it_behaves_like :no_access
      end
    end

    context 'when it is applied to the space' do
      before do
        space.space_quota_definition = object
        space.save
      end

      context 'space manager' do
        before do
          org.add_user(user)
          space.add_manager(user)
        end

        it_behaves_like :read_only_access
      end

      context 'space developer' do
        before do
          org.add_user(user)
          space.add_developer(user)
        end

        it_behaves_like :read_only_access
      end

      context 'space auditor' do
        before do
          org.add_user(user)
          space.add_auditor(user)
        end

        it_behaves_like :read_only_access
      end
    end

    context 'organization auditor (defensive)' do
      before { org.add_auditor(user) }
      it_behaves_like :no_access
    end

    context 'organization billing manager (defensive)' do
      before { org.add_billing_manager(user) }
      it_behaves_like :no_access
    end

    context 'organization user (defensive)' do
      before { org.add_user(user) }
      it_behaves_like :no_access
    end

    context 'user in a different organization (defensive)' do
      before do
        different_organization = FactoryBot.create(:organization)
        different_organization.add_user(user)
      end

      it_behaves_like :no_access
    end

    context 'manager in a different organization (defensive)' do
      before do
        different_organization = FactoryBot.create(:organization)
        different_organization.add_manager(user)
      end

      it_behaves_like :no_access
    end

    context 'a user that isnt logged in (defensive)' do
      let(:user) { nil }

      it_behaves_like :no_access
    end

    context 'any user using client without cloud_controller.write' do
      let(:scopes) { ['cloud_controller.read'] }

      before do
        org.add_user(user)
        org.add_manager(user)
        org.add_billing_manager(user)
        org.add_auditor(user)
        space.add_manager(user)
        space.add_developer(user)
        space.add_auditor(user)
      end

      it_behaves_like :read_only_access
    end

    context 'any user using client without cloud_controller.read' do
      let(:scopes) { [] }

      before do
        org.add_user(user)
        org.add_manager(user)
        org.add_billing_manager(user)
        org.add_auditor(user)
        space.add_manager(user)
        space.add_developer(user)
        space.add_auditor(user)
      end

      it_behaves_like :no_access
    end
  end
end