# Overview

`geomatch-central` - Manages resources that need to be reused across GeoMatch implementations (i.e. DNS).
It is self contained and should be on a separate account. Resources from here needed by other modules should be
accessed with data blocks instead of remote state.

`geomatch-ecs` - Module that can be instantiated by each implementation to setup GeoMatch infrastructure:

![GeoMatch-Hosted AWS](./GeoMatch-Hosted%20AWS%20Architecture.png)

# Naming Conventions

## Terraform Naming

Should follow the [Terraform best practices](https://www.terraform-best-practices.com/naming).
Most notably, use underscores for variable names, and use `this` for resource names only used
once in a module.

## Variable Values

All variable values should be lowercase with words separated by hypens.

Additional restrictions are documented in `variables.tf`.

## AWS Resource Names

All AWS resource names should be formated as:
`{project-name}-{environment}-{resource-name}`

In the above example, `resource-name` should be descriptive of the resource, such as `ecs-service-role` or `ecs-service-role-policy`. It may also be omitted where it makes sense (e.g. log group is named `{project-name}-{environment}`
because there should only logically be a single log group per environment)

When referring to the GeoMatch web server, prefer the name `app` (i.e. `app-server`, `app-container`, `app`, ...).

## Tags

The following tags should be present on each resource:

```
Project = "Project Name"
Environment   = "Environment"
```

# Usage

## AWS Profile Setup

See the [AWS Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds) on creating a key pair.

The IAM user created should have the `AdministratorAccess` policy.

## GitHub Module Setup

You can use any module in this folder, but first you must create an SSH key for Github's `Deploy Keys` (Assuming you're running terraform locally):

`ssh-keygen -t ed25519 -C "git@github.com-geomatch-deploy:GeoMatch/geomatch-deployment.git"`

Then append the appropriate ssh config:

`vim ~/.ssh/config`

```
Host github.com-geomatch-deploy
  Hostname github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

And add your passphrase to ssh-agent:

`ssh-add [-K if on MacOS] ~/.ssh/id_ed25519`

Next add the contents of `~/.ssh/id_ed25519.pub` to [geomatch-deployment's Deploy Keys](https://github.com/GeoMatch/geomatch-deployment/settings/keys).

Finally, you can source the module:

```terraform
module "geomatch_ecs" {
  source = "git::https://github.com/GeoMatch/geomatch-deployment.git//terraform/geomatch_app/ecs?ref=production"
  environment = "prod"
  project = "geomatch-[country]"
  some_var = "some-value"
  ...
}
```

The `ref` param will be the branch of this repo to pull.

TODO

- [ ] Setting up Github action to deploy with https://github.com/webfactory/ssh-agent
- [ ] See if a github action for ECS deploy can verify what resources are in the plan
and fail if there's unexpected ones.
- [ ] Output build args needed in github build from ecs module
- [ ] Seperate out networking
