job {
    name 'dumbo-journald-cloudwatch-logs-build'
    using 'TEMPLATE-autobuild'
    scm {
        git {
            remote {
                github 'dumbo/journald-cloudwatch-logs', 'ssh', 'git-aws.internal.justin.tv'
                credentials 'git-aws-read-key'
            }
            clean true
            branches 'origin/master'
        }
    }
    wrappers{
        credentialsBinding {
            string('dta_tools_deploy', 'dtatoolsdeploy')
            file('AWS_CONFIG_FILE', 'dumbo_repo')
        }
    }
    steps {
        shell 'rm -rf pkg'
        shell 'manta -v  -E ITERATION=\${BUILD_NUMBER}'
        shell 'cp pkg/dumbo-journald-cloudwatch-logs_*.deb pkg/dumbo-journald-cloudwatch-logs.deb'
        uploadDeb "pkg/dumbo-journald-cloudwatch-logs.deb", ['xenial', 'bionic']
        shell 'aws --profile dumbo_repo s3 cp pkg/dumbo-journald-cloudwatch-logs_*.deb s3://dumbo-repo/dumbo/'
    }
}

