cp values_template.yaml values.yaml

while IFS='=' read -r key value
do
  if [ -n "$key" ]; then
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
    
    if [ "$key" = "ca_certificate" ]; then
      if [ -f "$value" ]; then
        file_content=$(awk '{printf "%s\\n", $0}' "$value")
        sed -i "s|<$key>|$file_content|g" values.yaml
      else
        echo "File $value not found!"
      fi
    else
      sed -i "s|<$key>|$value|g" values.yaml
    fi
  fi
done < .env
