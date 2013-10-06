Feature: Manage WordPress posts

  Background:
    Given a WP install

  Scenario: Creating/updating/deleting posts
    When I run `wp post create --post_title='Test post' --porcelain`
    Then STDOUT should be a number
    And save STDOUT as {POST_ID}

    When I run `wp post update {POST_ID} --post_title='Updated post'`
    Then STDOUT should be:
      """
      Success: Updated post {POST_ID}.
      """

    When I run `wp post delete {POST_ID}`
    Then STDOUT should be:
      """
      Success: Trashed post {POST_ID}.
      """

    When I run the previous command again
    Then STDOUT should not be empty

    When I try the previous command again
    Then the return code should be 1

  Scenario: Creating/getting/editing posts
    Given a content.html file:
      """
      This is some content.

      It will be inserted in a post.
      """
    And a command.sh file:
      """
      cat content.html | wp post create --post_title='Test post' --post_excerpt="A multiline
      excerpt" --porcelain -
      """

    When I run `bash command.sh`
    Then STDOUT should be a number
    And save STDOUT as {POST_ID}

    When I run `wp eval '$post_id = {POST_ID}; echo get_post( $post_id )->post_excerpt;'`
    Then STDOUT should be:
      """
      A multiline
      excerpt
      """

    When I run `wp post get --field=content {POST_ID}`
    Then STDOUT should be:
      """
      This is some content.

      It will be inserted in a post.
      """

    When I run `wp post get --format=table {POST_ID}`
    Then STDOUT should be a table containing rows:
      | Field      | Value     |
      | ID         | {POST_ID} |
      | post_title | Test post |

    When I run `wp post get --format=json {POST_ID}`
    Then STDOUT should be JSON containing:
      """
      {
        "ID": {POST_ID},
        "post_title": "Test post"
      }
      """

    When I try `EDITOR='ex -i NONE -c q!' wp post edit {POST_ID}`
    Then STDERR should contain:
      """
      No change made to post content.
      """
    And the return code should be 0

    When I try `EDITOR='ex -i NONE -c %s/content/bunkum -c wq' wp post edit {POST_ID}`
    Then STDERR should be empty
    Then STDOUT should contain:
      """
      Updated post {POST_ID}.
      """

    When I run `wp post get --field=content {POST_ID}`
    Then STDOUT should contain:
      """
      This is some bunkum.
      """


  Scenario: Creating/listing posts
    When I run `wp post create --post_title='Publish post' --post_content='Publish post content' --post_status='publish' --porcelain`
    Then STDOUT should be a number
    And save STDOUT as {POST_ID}

    When I run `wp post create --post_title='Draft post' --post_content='Draft post content' --post_status='draft' --porcelain`
    Then STDOUT should be a number

    When I run `wp post list --post_type='post' --fields=post_title,post_name,post_status --format=csv`
    Then STDOUT should be CSV containing:
      | post_title   | post_name    | post_status  |
      | Publish post | publish-post | publish      |
      | Draft post   |              | draft        |

    When I run `wp post list --post_type='post' --post__in={POST_ID} --fields=post_title,post_name,post_status --format=csv`
    Then STDOUT should be CSV containing:
      | post_title   | post_name    | post_status  |
      | Publish post | publish-post | publish      |

    When I run `wp post list --post_type='page' --field=title`
    Then STDOUT should be:
      """
      Sample Page
      """
