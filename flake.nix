# NOTE: want to make this easier? consider contributing some of these packages to nixpkgs!
{
  description = "A very basic flake";

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # Allow NVIDIA stuff
            config.allowUnfree = true;

            # Enable CUDA for pytorch only, not for OpenCV, sklearn, etc.
            overlays = [
              (self: super: rec {
                python = super.python.override {
                  packageOverrides = self: super: {
                    torch = super.python.pkgs.torch.overrideAttrs {
                      cudaSupport = true;
                    };
                  };
                };
                pythonPackages = python.pkgs;
              })
            ];
          };
          qudida = pkgs.python310.pkgs.buildPythonPackage
            rec {
              version = "0.0.4";
              pname = "qudida";
              format = "pyproject";

              meta = with pkgs.lib; {
                description = "A micro library for very naive though quick pixel level image domain adaptation";
                homepage = "https://github.com/arsenyinfo/qudida";
                license = licenses.mit;
              };

              buildInputs = with pkgs.python310.pkgs; [
                numpy
                opencv4
                scikit-learn
                scipy
                typing-extensions
              ];

              preBuild = ''
                # TODO: this is probably not a good practice
                substituteInPlace setup.py \
                  --replace 'CHOOSE_INSTALL_REQUIRES = [' 'CHOOSE_INSTALL_REQUIRES = []; _ = ['
                substituteInPlace setup.py \
                  --replace '"opencv-python>=4.0.1", ' ""
                substituteInPlace setup.py \
                  --replace '"numpy>=0.18.0", ' ""
                substituteInPlace setup.py \
                  --replace '"scikit-learn>=0.19.1", ' ""
                substituteInPlace setup.py \
                  --replace '"typing-extensions"' ""
              '';

              src = pkgs.python310.pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-2xmOKIerDJqgAj5WWvv/Qd+3azYfhf1eE/eA11uhjMg=";
              };
            };
          albumentations = pkgs.python310.pkgs.buildPythonPackage
            rec {
              version = "1.3.0";
              pname = "albumentations";
              format = "pyproject";

              meta = with pkgs.lib; {
                description = "A Python library for image augmentation";
                homepage = "https://github.com/albumentations-team/albumentations";
                license = licenses.mit;
              };

              buildInputs = with pkgs; [
                python310.pkgs.scipy
                python310.pkgs.numpy
                python310.pkgs.pyyaml
                python310.pkgs.scikitimage
                qudida
              ];

              preBuild = ''
                # TODO: this is probably not a good practice
                substituteInPlace setup.py \
                  --replace 'CHOOSE_INSTALL_REQUIRES = [' 'CHOOSE_INSTALL_REQUIRES = []; _ = ['
                substituteInPlace setup.py \
                  --replace 'INSTALL_REQUIRES = [' 'INSTALL_REQUIRES = []; _ = ['
              '';

              src = pkgs.python310.pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-vhrzaDLIiTMU8qVVDorBmAHgR3BzTBtw+jyZa0Hze+0=";
              };
            };
          kornia = pkgs.python310.pkgs.buildPythonPackage
            rec {
              version = "0.0.1";
              pname = "kornia";
              format = "pyproject";

              meta = with pkgs.lib; {
                description = "Kornia is a differentiable computer vision library for PyTorch.";
                license = licenses.asl20;
              };

              buildInputs = with pkgs; [
                python310.pkgs.pytorch
              ];

              installPhase = ''
                PY_V="3.10"
                OUT=$out/lib/python$PY_V/site-packages/
                mkdir -p $OUT
                mv ${pname} $OUT
              '';

              src = fetchGit {
                url = "https://github.com/kornia/kornia.git";
                ref = "master";
                rev = "5422be7146a4591d156f1932d08fcb0f6e011902";
              };
            };
          clip = pkgs.python310.pkgs.buildPythonPackage
            rec {
              version = "0.0.1";
              pname = "clip";
              format = "pyproject";

              meta = with pkgs.lib; {
                description = "CLIP (Contrastive Language-Image Pre-Training) is
              a neural network trained on a variety of (image, text) pairs";
                homepage = "https://github.com/openai/CLIP";
                license = licenses.mit;
              };

              buildInputs = with pkgs; [
                python310.pkgs.numpy
                python310.pkgs.pytorch
                python310.pkgs.pytorch-lightning
                python310.pkgs.ftfy
              ];

              installPhase = ''
                PY_V="3.10"
                OUT=$out/lib/python$PY_V/site-packages/
                mkdir -p $OUT
                mv ${pname} $OUT
              '';

              src = fetchGit {
                url = "https://github.com/openai/CLIP.git";
                ref = "main";
                rev = "d50d76daa670286dd6cacf3bcd80b5e4823fc8e1";
              };
            };
          taming-transformers = pkgs.python310.pkgs.buildPythonPackage
            rec {
              version = "0.0.1";
              pname = "taming";
              format = "pyproject";

              meta = with pkgs.lib; {
                description = "Taming Transformers for High-Resolution Image Synthesis";
                homepage = "https://github.com/CompVis/taming-transformers";
                license = licenses.mit;
              };

              buildInputs = with pkgs; [
                python310.pkgs.numpy
                python310.pkgs.omegaconf
                python310.pkgs.pytorch
                python310.pkgs.pytorch-lightning
                python310.pkgs.torchvision
                python310.pkgs.tqdm
              ];

              installPhase = ''
                PY_V="3.10"
                OUT=$out/lib/python$PY_V/site-packages/
                mkdir -p $OUT
                mv ${pname} $OUT
              '';

              src = fetchGit {
                url = "https://github.com/CompVis/taming-transformers.git";
                ref = "master";
                rev = "24268930bf1dce879235a7fddd0b2355b84d7ea6";
              };
            };
        in
        {
          #defaultPackage = stable-diffusion;
          devShell =
            let py = pkgs.python310.withPackages (p: with p; [
              albumentations
              clip
              pkgs.cudatoolkit_11
              einops
              ftfy
              imageio
              kornia
              numpy
              omegaconf
              opencv4
              pudb
              pytorch
              pytorch-lightning
              qudida
              scikit-learn
              scikitimage
              taming-transformers
              torchvision
              transformers
            ]);
            in
            pkgs.mkShell {
              buildInputs = [
                pkgs.fortune
                py
              ];
              shellHook = ''
                if [ ! -d stable-diffusion ]; then
                  git clone https://github.com/basujindal/stable-diffusion.git
                fi
                mkdir -p sd-data
                cd stable-diffusion

                export PYTHONPATH=$(pwd):$PYTHONPATH
                export CUDA_PATH=${pkgs.cudatoolkit_11}

                echo "Don't forget to symlink the model weights as described in https://github.com/basujindal/stable-diffusion"
                echo "Happy painting!"
              '';
            };
        });
}
