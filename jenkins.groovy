job {
    name 'journald-cloudwatch-logs-build'
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
    steps {
        shell 'rm -rf pkg'
        shell 'manta -v  -E ITERATION=\${BUILD_NUMBER}'
        uploadDeb "pkg/journald-cloudwatch-logs.deb", ['xenial', 'bionic']
    }
}

