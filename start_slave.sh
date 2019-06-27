kubeadm token create --print-join-command > $HOME/join_command.sh
join=$(cat $HOME/join_command.sh )
input="$HOME/slave_ip.txt"
for HOST in $(cat $HOME/slave_ip.txt)
do
echo "ssh -oStrictHostKeyChecking=no ubuntu@$HOST -tty "sudo $join""
ssh -oStrictHostKeyChecking=no ubuntu@$HOST -tty "sudo $join"
done;
