describe Api::ToolDraftsController do
  before do
    set_as_mmt_proper
    @request.headers['Authorization'] = 'Bearer access-token'
    @tool_draft = create(:full_tool_draft, user: create(:user, :multiple_providers))
    @test_user2 = create(:user2) # belong to LARC
  end

  it 'shows draft tool record for mmt proper' do
    # The draft is created by a MMT_2 user
    # The user requesting the document does have MMT_2 in their provider list.
    allow_any_instance_of(Cmr::UrsClient).to receive(:validate_mmt_token).and_return(Faraday::Response.new(status: 200, body: '{"uid":"testuser"}', response_headers: {'Content-Type':'application/json; charset=utf-8'}))
    get :show, params: { id: @tool_draft.id }
    parsed_body = JSON.parse(response.body)
    draft_json = @tool_draft.draft
    assert_equal(parsed_body['Name'], draft_json['Name'])
  end

  it 'it responds unauthorized if the user does not belong to the provider list.' do
    # The draft is created by a MMT_2 user
    # The user requesting the document does not have MMT_2 in their provider list, only 'LARC'
    allow_any_instance_of(Cmr::UrsClient).to receive(:validate_mmt_token).and_return(Faraday::Response.new(status: 200, body: '{"uid":"testuser2"}', response_headers: {'Content-Type':'application/json; charset=utf-8'}))
    get :show, params: { id: @tool_draft.id }
    parsed_body = JSON.parse(response.body)
    assert_equal(parsed_body['error'], 'unauthorized')
  end

  it 'create draft record' do
    response = Faraday.post("http://localhost:3000/api/tool_drafts") do |req|
      req.body = '{"draft": {"Name": "a name", "LongName": "a tool description", "Version": "10.0"}}'
    end
    expect(response.status).to eq(204)
  end

end