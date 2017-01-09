class AzureCli < Formula
  include Language::Python::Virtualenv

  desc "Microsoft Azure CLI 2.0"
  homepage "https://docs.microsoft.com/en-us/cli/azure/overview"
  head "https://github.com/Azure/azure-cli.git"
  url "https://azurecliprod.blob.core.windows.net/releases/azure-cli_packaged_2.0.15.tar.gz"
  sha256 "a2d7ce40367f0bccf7da2a599214175fb88aeb88f869ac6b06be8593d04959d6"

  depends_on :python if MacOS.version <= :snow_leopard

  def install
    virtualenv_create(libexec)

    # Get the components we'll install
    components = [
      buildpath/"src/azure-cli",
      buildpath/"src/azure-cli-core",
      buildpath/"src/azure-cli-nspkg",
      buildpath/"src/azure-cli-command_modules-nspkg"
    ]
    components += Pathname.glob(buildpath/"src/command_modules/azure-cli-*/")

    # Build wheels
    components.each do |item|
      Dir.chdir(item) { system libexec/"bin/python", "setup.py", "bdist_wheel", "-d", buildpath/"dist" }
    end

    # Install CLI using built wheels
    system libexec/"bin/pip", "install", "azure-cli", "-f", buildpath/"dist"

    # Create executable
    az_exec = <<-EOS.undent
      #!/usr/bin/env bash
      #{libexec}/bin/python -m azure.cli \"$@\"
    EOS
    (bin/"az").write(az_exec)

    # Install bash completion
    bash_completion.install "az.completion" => "az"
  end

  def caveats; <<-EOS.undent
  This formula is for Azure CLI 2.0 - https://docs.microsoft.com/en-us/cli/azure/overview.
  The previous Azure CLI has moved to azure-cli@1.0.
  ----
  Get started with:
    $ az
  EOS
end

  test do
    version_output = shell_output("#{bin}/az --version")
    assert_match "azure-cli", version_output
    system bin/"az", "account", "list"
  end
end
