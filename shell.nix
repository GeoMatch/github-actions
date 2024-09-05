with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "node";
  buildInputs = [ 
    nodejs-18_x
    awscli2
    # Used for lambda type completion:
    python3
    python3Packages.pip
  ];

  shellHook = ''
    export PYTHONPATH=${pkgs.python3.sitePackages}:$PYTHONPATH
    python3 -m venv .venv
    source .venv/bin/activate
    pip install boto3 boto3-stubs[essential] black
    source_lambda_env() {
      while IFS= read -r line; do
          # Skip empty lines and lines starting with #
          if [[ ! -z "$line" && ! "$line" =~ ^# ]]; then
              export "$line"
          fi
      done < .env.lambda
    }
    lambda_instances() {
      # Execute in a subshell to avoid polluting the environment
      (
        source_lambda_env
        python terraform/geomatch_app/sftp/lambda_source/instances.py
      )
    }
    lambda_access() {
      # Execute in a subshell to avoid polluting the environment
      (
        source_lambda_env
        python terraform/geomatch_app/sftp/lambda_source/access.py
      )
    }
  '';
}