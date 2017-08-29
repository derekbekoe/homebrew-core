class AzureCli < Formula
  include Language::Python::Virtualenv

  desc "Microsoft Azure CLI 2.0"
  homepage "https://docs.microsoft.com/cli/azure/overview"
  url "https://azurecliprod.blob.core.windows.net/releases/azure-cli_packaged_2.0.15-2.tar.gz"
  sha256 "76b0da109abc7ee9eb70f53ff90e72e466ae4e8dcaa21752cbdfe105a408724c"
  head "https://github.com/Azure/azure-cli.git"

  depends_on :python if MacOS.version <= :snow_leopard
  depends_on "openssl"

  def install
    ENV.prepend "LDFLAGS", "-L#{Formula["openssl"].opt_lib}"
    ENV.prepend "CFLAGS", "-I#{Formula["openssl"].opt_include}"
    ENV.prepend "CPPFLAGS", "-I#{Formula["openssl"].opt_include}"

    virtualenv_create(libexec)

    # Get the components we'll install
    components = [
      buildpath/"src/azure-cli",
      buildpath/"src/azure-cli-core",
      buildpath/"src/azure-cli-nspkg",
      buildpath/"src/azure-cli-command_modules-nspkg",
    ]
    components += Pathname.glob(buildpath/"src/command_modules/azure-cli-*/")

    # Build source distributions
    components.each do |item|
      Dir.chdir(item) { system libexec/"bin/python", "setup.py", "sdist", "-d", buildpath/"dist" }
    end

    # Install CLI using source distributions only
    system libexec/"bin/pip", "install", "--no-binary", ":all:", "azure-cli", "-f", buildpath/"dist"
    system libexec/"bin/pip", "install", "--no-binary", ":all:", "--force-reinstall", "-U", "azure-nspkg", "azure-mgmt-nspkg", "-f", buildpath/"dist"

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
    This formula is for Azure CLI 2.0 - https://docs.microsoft.com/cli/azure/overview.
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
