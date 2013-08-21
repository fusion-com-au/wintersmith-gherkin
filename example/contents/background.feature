@test
Feature: Background and tags
	As a Mephisto site owner
	I want to host blogs for different people
	In order to make gigantic piles of money

	@bg
	Background:
		Given a global administrator named "Greg"
		And a blog named "Greg's anti-tax rants"
		And a customer named "Dr. Bill"
		And a blog named "Expensive Therapy" owned by "Dr. Bill"

	Scenario: Dr. Bill posts to his own blog
		Given I am logged in as Dr. Bill
		When I try to post to "Expensive Therapy"
		Then I should see "Your article was published."

	@s2 @bill
	Scenario: Dr. Bill tries to post to somebody else's blog, and fails
		Given I am logged in as Dr. Bill
		When I try to post to "Greg's anti-tax rants"
		Then I should see "Hey! That's not your blog!"

	@s3
	Scenario: Greg posts to a client's blog
		Given I am logged in as Greg
		When I try to post to "Expensive Therapy"
		Then I should see "Your article was published."
