#!/bin/bash
echo
echo " [ $(basename $BASH_SOURCE) ] "
shasum -a 256 *
shasum -a 256 --check shasum256.txt

TMUX_SS="$(date +%b%m%H%M%S)"
EC_KY=$(cat << 'EOF'
U2FsdGVkX1/KUzkWzAbDQxcdTdD1KqVMcbukPBJbleAo9dvaVQEeWF760jCdRdAzwGKw6xcZpen5EJvabeZfw8JleYXSZm/ZUmx5P14v9FAGL/Yky1dM+nJsFTQaIuP8ndQFStlxJqMjA9bgvHak9oPKbHNyR6G8apGorB0MPfcxEdj+/4YBGVE2Vi90gtwf0y7Ko8X0iQn5jomHNDSi5WWrvPN+ZtL09oTZU99/+Flis518Z/sxcQC6+0cocs/60jRHW734x0/EH68z16MZwyWL0hKJ10OQQutUvVQWH3wHNBeTaPEThXGZTgSMMuTy/p0qiWnnOnbP2MGZxc6+Y5KN8OeUPgBQtYtAHwQXP+duCAX9q/xzcoMHypgQQa2qxHf/guyWrhv+QqiVJ7EN3ytjaghpPHZMrOuc4Fqfg5UFEmp3PlgX0Rw56sT7/UCfm5kaUT4mnpvj+v7EPqxSKkGynz06tBFyobvKh9vJ1tv9ipHkMfl6Xmm4LUI9HeaX/XXi60x8ICJQQfSGAcqjDH0JFh4ma4aeTJzmAEwqieU=
EOF
)
eval "$(ssh-agent -s)"
AGENT_PID=$!
trap 'ssh-agent -k > /dev/null; echo "ssh-agent killed";' EXIT

echo -n "DEC: (+1+1+1)"
read -s PASD
echo

if [ "$1" == "init" ]; then
mkdir -p .ssshhh
openssl aes-256-cbc -d -salt -pass pass:"$PASD" -in <(echo "$EC_KY" | base64 -d) -out .ssshhh/l
unset PASD
chmod 600 .ssshhh/l
tee Makefile <<'EOF'
l:
	@ssh  -t -i .ssshhh/l -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "l@MacBook-Air.local" "tmux attach || tmux"
.PHONY: l
git:
	git rebase -i  --root main
	GIT_AUTHOR_NAME="noname" GIT_AUTHOR_EMAIL="noemail" GIT_COMMITTER_NAME="noname" GIT_COMMITTER_EMAIL="noemail" git commit --amend --no-edit --reset-author
.PHONY: git
clean:
	rm -rf .ssshhh Makefile
.PHONY: clean
EOF
exit 0
fi

openssl aes-256-cbc -d -salt -pass pass:"$PASD" -in <(echo "$EC_KY" | base64 -d) | ssh-add -
unset PASD

if [ "$1" == "ssh" ]; then
ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "l@MacBook-Air.local" "tmux attach || tmux"
exit 0
fi

rsync -avz --chmod=u+rwx,g-rwx,o-rwx -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" z*.sh l@MacBook-Air.local:/home/l/

if [ "$1" == "rsync" ]; then
exit 0
fi

ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "l@MacBook-Air.local" << EOF
tmux new-session -d -s "$TMUX_SS"
tmux send-keys -t "$TMUX_SS" "./z1-env-setup.sh && ./z2-config-setup.sh && ./z3-docker-setup.sh && ./z4-network-setup.sh && ./z5-app-setup.sh " C-m
EOF

echo
echo "Job continued in tmux session: $TMUX_SS "
echo

ssh  -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "l@MacBook-Air.local" "tmux attach"

