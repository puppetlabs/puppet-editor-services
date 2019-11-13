# An overview on how to release the editor services

1. Generate and merge a release prep

    * Move the Unreleased parts of the changelog to the released section

    * Modify `lib/puppet_editor_services/version.rb` with the new version number

2. Once merged get the commit id of the preparation

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

    ``` powershell
    PS> git checkout 0.11.0
    PS> git reset --hard 0.11.0
    ```

6. Build the artefacts

    `bundle exec rake build`

7. Enure the version is correct in the `/output` directory

8. Upload the artefacts to github using the `upload_release.ps1` PowerShell script

    For example;

    ``` powershell
    PS> .\tools\upload_release.ps1 -ReleaseVersion '0.11.0' -GithubUserName 'glennsarti' -GithubToken abc123
    ```
