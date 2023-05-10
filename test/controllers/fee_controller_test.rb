require "test_helper"

class FeeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get fee_index_url
    assert_response :success
  end
end
