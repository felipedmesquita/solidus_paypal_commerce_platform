require 'solidus_paypal_commerce_platform_spec_helper'

RSpec.describe SolidusPaypalCommercePlatform::WizardController, type: :request do
  stub_authorization!

  let(:wizard) { SolidusPaypalCommercePlatform::Wizard.new }

  describe "POST /solidus_paypal_commerce_platform/wizard" do
    let(:params) {
      {
        authCode: "PFc4d2vp4DVfHqcnEHbGAA12C_H29U39NM_vmQrZBPzdLcxA12Br-GzjbliqXGu3AG6Gfwo5G9GTal6REkcKGMREc9fPsR_wv",
        sharedId: "awj45zMAy1XonxWfgIhjjGHZGAPStkZFzXp4bfe1QmNWA-9DL6HkpklD0skHig4vVF7zVZD8Uwy5Qop4",
        nonce: wizard.nonce,
      }
    }

    it "creates a new payment method from data received from PayPal" do
      expect_any_instance_of(SolidusPaypalCommercePlatform::Client).to receive(:execute) do |_client, request|
        case request
        when SolidusPaypalCommercePlatform::AccessTokenAuthorizationRequest
          # rubocop:disable RSpec/VerifiedDoubles
          double(
            'response',
            result: double(
              'result',
              access_token: "ACCESS-TOKEN"
            )
          )
          # rubocop:enable RSpec/VerifiedDoubles
        when SolidusPaypalCommercePlatform::FetchMerchantCredentialsRequest
          expect(request.headers.fetch("Authorization")).to eq("Bearer ACCESS-TOKEN")

          # rubocop:disable RSpec/VerifiedDoubles
          double(
            'response',
            result: double(
              'result',
              client_id: "CLIENT-ID",
              client_secret: "CLIENT-SECRET",
            )
          )
          # rubocop:enable RSpec/VerifiedDoubles
        else
          raise "unexpected request: #{request}"
        end
      end.twice

      expect {
        post solidus_paypal_commerce_platform.wizard_index_path, params: params
      }.to change(SolidusPaypalCommercePlatform::PaymentMethod, :count).from(0).to(1)

      payment_method = SolidusPaypalCommercePlatform::PaymentMethod.last

      expect(payment_method.preferred_client_id).to eq("CLIENT-ID")
      expect(payment_method.preferred_client_secret).to eq("CLIENT-SECRET")
      expect(response).to have_http_status(:created)
    end
  end
end
