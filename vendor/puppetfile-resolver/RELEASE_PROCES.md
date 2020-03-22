# An overview on how to release the puppetfile-resolver gem

1. Generate and merge a release prep

    * Move the Unreleased parts of the changelog to the released section

    * Modify `lib/puppetfile-resolver/version.rb` with the new version number

    * Update the YARD Reference documentation using `bundle exec rake generate:docs`

    * Update the SSL Certs File using `bundle exec rake ssl:vendor_ca_certs`

2. Once merged, get the commit id of the preparation

3. Tag the commit

    `git tag -a '<version>' -m '<version>' <commit id>`

    For example;
    `git tag -a '0.11.0' -m '0.11.0' 8766a5dd5e476bb10c164962e8d9185810e96a17`

4. Push the commit

    `git push <remote> <version>`

    For example;
    `git push upstream 0.11.0`

5. Checkout and reset the repo for the new tag

    For example;

    ``` text
    > git checkout 0.11.0
    > git reset --hard 0.11.0
    ```

6. Build the artefacts

    `gem build puppetfile-resolver`

7. Upload the artefacts to ruby gems

    ``` text
    > git push puppetfile-resolver-0.11.0.gem
    ```
