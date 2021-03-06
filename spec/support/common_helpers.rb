# encoding: utf-8
#
# Helpers for testing the application
#

module CommonHelpers

  #
  # User authentication
  #
  # Visits the login form and login with the password 'password'
  # unless another one is passed as an option
  #
  # @param [User]  user  User to authenticate.
  # @param [Hash]  opts  +password+: password used for authentication.
  def sign_in_as_user(user, opts = {})
    options = { :context => "#new_user", :path => new_user_session_path, :password => 'password' }
    options.merge!(opts)
    visit options[:path] if options[:path]
    within(options[:context]) do
      fill_in "email", :with => user.email
      fill_in "password", :with => options[:password]
      click_button "Sign in"
    end
  end

  #
  # Destroys current user session
  #
  def logout
    click_link "Log out"
  end

  #
  # Find a given request through the index view
  #
  # Logs in as a user, goes to the list of requests and clicks on the given
  # request. At the moment of calling, no user should be already signed in.
  #
  # @param [User]    user     User to authenticate
  # @param [Request] request  Request to look for
  # @param [Hash]    opt      +password+: password used for authentication
  def find_request_as(user, request, opts = {})
    sign_in_as_user(user, opts)
    visit requests_path
    find(:xpath, "//table[contains(@class,'requests')]//tbody/tr/td[1]//a[text()='##{request.id}']").click
    page.should have_content "request"
    request.expenses.each do |e|
      page.should have_content e.subject
      page.should have_content e.description
    end
  end

  #
  # Find a given reimbursement through the index view
  #
  # Logs in as a user, goes to the list of reimbursements and clicks on the given
  # one. At the moment of calling, no user should be already signed in.
  #
  # @param [User]    user     User to authenticate
  # @param [Reimbursement] reimbursement  Reimbursement to look for
  # @param [Hash]    opt      +password+: password used for authentication
  def find_reimbursement_as(user, reimbursement, opts = {})
    sign_in_as_user(user, opts)
    visit reimbursements_path
    find(:xpath, "//table//tbody/tr/td[1]//a[text()='##{reimbursement.id}']").click
    page.should have_content "reimbursement"
    reimbursement.expenses.each do |e|
      page.should have_content e.subject
      page.should have_content e.description
    end
  end

  #
  # Reveals the hidden inputs (type=file) from bootstrap-uploader
  #
  # Look for Jasny's bootstrap-fileuploads that match the locator and make them
  # visible in order to be accessible to regular helpers like attach_file
  #
  # @param [String]    locator     CSS selector
  def show_jasny_file_inputs(locator)
    page.execute_script(%Q{$("#{locator}").css('opacity', 1)})
    page.execute_script(%Q{$("#{locator}").css('transform', 'none')})
    page.execute_script(%Q{$("#{locator}").css('position', 'relative')})
  end

  #
  # Creates a StateTransition for a request or a reimbursement
  #
  # @param [#state]  machine      Request or Reimbursement
  # @param [Symbol]  state_event  Event to trigger on the event machine
  # @param [User]    user         Obvious
  def transition(machine, state_event, user)
      submission = StateTransition.new(:state_event => state_event.to_s)
      submission.machine = machine
      submission.user = user
      submission.save!
  end

  #
  # Closes a modal dialog and waits until it's really closed
  #
  def close_modal_dialog
    within(".modal") do
      click_link "Back"
    end
    page.should_not have_css(".modal-backdrop", :wait => 15)
  end

  #
  # Creates a state adjustment through the web interface
  #
  # @param [#state] machine      Request or Reimbursement
  # @param [#to_s]  state        Target state
  def adjust_state(machine, state)
    if machine.kind_of? Reimbursement
      find_reimbursement_as users(:supervisor), machine
    else
      find_request_as users(:supervisor), machine
    end
    click_link "Adjust state"
    select state.to_s, :from => :state_adjustment_to
    click_button "Create state adjustment"
    logout
  end

  #
  # Assign a file to the attribute acceptance_file
  #
  # param [Reimbursement] reimbursement Reimbursement object to assign the file
  # param [String]        filename      Name of the file located in support/files
  def set_acceptance_file(reimbursement, filename = "scan001.pdf")
    file = Rails.root.join("spec", "support", "files", filename)
    reimbursement.acceptance_file = File.open(file, "rb")
  end
end
