INSTANCES=$(aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId}' --output text)

for INSTANCE in ${INSTANCES[*]} ; do

   NAME=$(aws ec2 describe-instances --instance-id $INSTANCE --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value[]' --output text)
   VOLUMES=$(aws ec2 describe-instances --instance-id $INSTANCE --query 'Reservations[].Instances[].BlockDeviceMappings[].Ebs.{Volume:VolumeId}' --output text)

   for VOLUME in ${VOLUMES[*]} ; do
      DEV=$(aws ec2 describe-volumes --volume-id $VOLUME --query 'Volumes[*].{ZDev:Attachments[0].Device}' --output text)
      TAG=$NAME"("$DEV")"
      TAG2=$(echo $TAG | tr -d " " | tr -d "'")
      echo $VOLUME $TAG2
      aws ec2 create-tags --resources $VOLUME --tags Key=Name,Value=$TAG2
      aws ec2 create-tags --resources $VOLUME --tags Key=MakeSnapshot,Value=True
   done

done
