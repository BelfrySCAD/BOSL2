If you wish to contribute bugfixes or code to the BOSL2 project, the standard way is thus:

1. Install command-line git on your system and configure authentication.
    - https://docs.github.com/en/github/getting-started-with-github/set-up-git
1. Alternatively, you can install GitHub Desktop.
    - https://desktop.github.com
    - https://docs.github.com/en/desktop
1. Go to the main BOSL2 GitHub repo page: https://github.com/BelfrySCAD/BOSL2/
1. Fork the BOSL2 repository by clicking on the Fork button.
   
    - https://docs.github.com/en/github/getting-started-with-github/fork-a-repo
1. Clone your fork of the BOSL2 repository to your local computer:
    - If using the command-line:
        ```
        git clone git@github.com:YOURLOGIN/BOSL2.git
        cd BOSL2
        git remote add upstream https://github.com/BelfrySCAD/BOSL2.git
        ```
    
    - If using GitHub Desktop:
      
	    1. File -> Clone Repository...
	    2. Select your BOSL2 repository.
	    3. Click the Clone button.
	    4. When it asks "How are you planning to use this fork?", click on the button "To contribute to the parent project."
	
1. Before you edit files, always synchronize with the upstream repository:
    - If using the command-line:
        ```
        git pull upstream
        ```
    - If using GitHub Desktop, click on the Fetch Origin button.
1. Make changes in the source code that you want to make.
1. Commit the changes files to your repo:
    - If using the command-line:
        ```
        git add --all
        git commit -m "COMMIT DESCRIPTION"
        git pull upstream
        git push
        ```
    
    - If using GitHub Desktop:
        
        1. Select all changed files you want to commit.
        2. Enter the summary for the commit.
        3. Click on the Commit button.
        4. Click on the Push Origin button.
    
1. Go to your GitHub BOSL2 repo page.
1. Click on the `Pull Request` button, enter the description, then create the PR.
1. If a change you made fails to pass the regressions or docs validations, this will be noted at the bottom of your Pull Request page, and you will get an email about it.


