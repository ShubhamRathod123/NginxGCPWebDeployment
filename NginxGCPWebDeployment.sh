#!/bin/bash

project=$(gcloud projects list)
logFile=Prod.html

# Create the HTML report file
echo "<html>" > ${logFile}
echo "<head><title>GCP Server List and URL Generated at `date`</title>" >> ${logFile}
echo "<meta http-equiv='Content-Type' content='text/html;charset=utf-8' />" >> ${logFile}
echo "<meta http-equiv='Cache-Control' content='no-cache, no-store, must-revalidate' />" >> ${logFile}
echo "<meta http-equiv='Pragma' content='no-cache' />" >> ${logFile}
echo "<meta http-equiv='Expires' content='0' />" >> ${logFile}
echo "<style>table, th, td { border:1px solid black; }</style>" >> ${logFile}
echo "</head><body><table style='width:100%'><tr><th style='width:30%'>Server</th><th>Artifacts Versions</th></tr>" >> ${logFile}

warFiles=(
    "version.war:META-INF/MANIFEST.MF:Release-Version"
)

# Loop through each project
for project_id in ${project}
do
    echo "<tr><td style='text-align:center; vertical-align:middle; font-weight:bold' colspan=2>Project Name: ${project_id}</td></tr>" >> ${logFile}
    servers=$(gcloud compute instances list --project ${project_id} --sort-by=NAME --format='value(name)')
    for server in ${servers}; do
        #server=local
        echo "<tr><td style='text-align:left; vertical-align:middle'>${server}</td><td><pre>" >> ${logFile}
        #ssh_output="Hi"  
        # SSH into the server and retrieve WAR file versions
        warFilesString=$(printf "%s\n" "${warFiles[@]}")
        ssh_output=$(ssh $server bash <<EOF
        #!/bin/bash

        IFS=$'\n' read -r -d '' -a warFiles <<< "$warFilesString"
        output=""
        #cd /mount/WASApplications/deployed/
        for war in "\${warFiles[@]}"; do
            IFS=':' read -r warFile file key <<< \$war
            if [[ -f \$warFile ]]; then
                if [[ -z \$key ]]; then
                    version=\$(unzip -p "\$warFile" "\$file")
                else
                    version=\$(unzip -p "\$warFile" "\$file" | grep "\$key" | sed 's/=/:/g' | cut -d: -f2- | xargs)
                fi
                output+="\$warFile version: \$version\\n"
            fi
        done
        echo -e "\$output"
EOF
)
        echo "${ssh_output}" >> ${logFile}
        echo "</pre></td></tr>" >> ${logFile}
    done
done

echo "</table></body></html>" >> ${logFile}

cp ${logFile} /var/www/html/Prod.html