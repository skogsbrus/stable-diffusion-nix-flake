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
            config.cudaSupport = true;

            # Enable CUDA for pytorch only, not for OpenCV, sklearn, etc.
            # TODO: doesn't work :(
            overlays = [
              (self: super: rec {
                python3 = super.python3.override {
                  packageOverrides = self: super: {
                    pytorch = super.python3.pkgs.pytorch.overrideAttrs {
                      cudaSupport = true;
                    };
                    pytorch-lightning = super.python3.pkgs.pytorch-lightning.overrideAttrs {
                      cudaSupport = true;
                    };
                  };
                };
                pythonPackages = python3.pkgs;
                python310Packages = python3.pkgs;
              })
            ];
          };

          inherit (pkgs.python310.pkgs) buildPythonPackage fetchPypi;
          inherit (pkgs.python310.pkgs)
            ftfy
            numpy
            omegaconf
            opencv4
            pytorch
            pytorch-lightning
            pyyaml
            scikit-learn
            scikitimage
            scipy
            torchvision
            tqdm
            typing-extensions
            ;

          qudida = buildPythonPackage
            rec {
              version = "0.0.4";
              pname = "qudida";
              format = "pyproject";

              meta = with pkgs.lib; {
                description = "A micro library for very naive though quick pixel level image domain adaptation";
                homepage = "https://github.com/arsenyinfo/qudida";
                license = licenses.mit;
              };

              buildInputs = [
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

              src = fetchPypi {
                inherit pname version;
                sha256 = "sha256-2xmOKIerDJqgAj5WWvv/Qd+3azYfhf1eE/eA11uhjMg=";
              };
            };
          albumentations = buildPythonPackage
            rec {
              version = "1.3.0";
              pname = "albumentations";
              format = "pyproject";

              meta = {
                description = "A Python library for image augmentation";
                homepage = "https://github.com/albumentations-team/albumentations";
                license = pkgs.lib.licenses.mit;
              };

              buildInputs = [
                scipy
                numpy
                pyyaml
                scikitimage
                qudida
              ];

              preBuild = ''
                # TODO: this is probably not a good practice
                substituteInPlace setup.py \
                  --replace 'CHOOSE_INSTALL_REQUIRES = [' 'CHOOSE_INSTALL_REQUIRES = []; _ = ['
                substituteInPlace setup.py \
                  --replace 'INSTALL_REQUIRES = [' 'INSTALL_REQUIRES = []; _ = ['
              '';

              src = fetchPypi {
                inherit pname version;
                sha256 = "sha256-vhrzaDLIiTMU8qVVDorBmAHgR3BzTBtw+jyZa0Hze+0=";
              };
            };
          kornia = buildPythonPackage
            rec {
              version = "0.0.1";
              pname = "kornia";
              format = "pyproject";

              meta = {
                description = "Kornia is a differentiable computer vision library for PyTorch.";
                license = pkgs.lib.licenses.asl20;
              };

              buildInputs = [
                pytorch
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

              buildInputs = [
                numpy
                pytorch
                pytorch-lightning
                ftfy
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
                numpy
                omegaconf
                pytorch
                pytorch-lightning
                torchvision
                tqdm
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
          devShell =
            let py = pkgs.python310.withPackages (p: with p; [
              albumentations
              clip
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
                pkgs.cudatoolkit_11
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
