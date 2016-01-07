
git filter-branch --commit-filter '
	echo $GIT_AUTHOR_EMAIL >>/tmp/tt
      if [ "$GIT_AUTHOR_EMAIL" = "michel@midesk.bsiuk.com" ];
      then
              export GIT_AUTHOR_NAME="Michel Pollet";
              export GIT_AUTHOR_EMAIL="buserror@gmail.com";
              git commit-tree "$@";
      else
              git commit-tree "$@";
      fi' HEAD
