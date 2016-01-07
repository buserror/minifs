git filter-branch -f --commit-filter '
        if [ "$GIT_AUTHOR_EMAIL" = "michel@midesk.bsiuk.com" ];
        then
                GIT_AUTHOR_NAME="Michel Pollet";
                GIT_AUTHOR_EMAIL="buserror@gmail.com";
                git commit-tree "$@";
		elif [ "$GIT_AUTHOR_EMAIL" = "mark@debian.BSI" ];
		then
                GIT_AUTHOR_NAME="Michel Pollet";
                GIT_AUTHOR_EMAIL="buserror@gmail.com";
                git commit-tree "$@";
		elif [ "$GIT_AUTHOR_EMAIL" = "michel@dhell.bsiuk.com" ];
		then
                GIT_AUTHOR_NAME="Michel Pollet";
                GIT_AUTHOR_EMAIL="buserror@gmail.com";
                git commit-tree "$@";
		elif [ "$GIT_AUTHOR_EMAIL" = "anthonym@bsiuk.com" ];
		then
                GIT_AUTHOR_NAME="Michel Pollet";
                GIT_AUTHOR_EMAIL="buserror@gmail.com";
                git commit-tree "$@";
		elif [ "$GIT_AUTHOR_EMAIL" = "skb@bsiuk-eng-kbala.BSIUK.l-3com.com" ];
		then
                GIT_AUTHOR_NAME="Michel Pollet";
                GIT_AUTHOR_EMAIL="buserror@gmail.com";
                git commit-tree "$@";
        else
                git commit-tree "$@";
        fi' $1..HEAD

