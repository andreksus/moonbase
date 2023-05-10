require "test_helper"

class PaymentHistoryControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get payment_history_index_url
    assert_response :success
  end
end
