import { ModalFuncProps } from 'antd/es/modal/Modal';
import { useCallback } from 'react';

import usePermissions from 'hooks/usePermissions';
import { paths } from 'routes/utils';
import { deleteModel } from 'services/api';
import useModal, {
  CANNOT_DELETE_MODAL_PROPS,
  ModalHooks as Hooks,
  ModalCloseReason,
} from 'shared/hooks/useModal/useModal';
import { clone } from 'shared/utils/data';
import { ErrorLevel, ErrorType } from 'shared/utils/error';
import { routeToReactUrl } from 'shared/utils/routes';
import { ModelItem } from 'types';
import handleError from 'utils/error';

interface Props {
  onClose?: (reason?: ModalCloseReason) => void;
}

interface ModalHooks extends Omit<Hooks, 'modalOpen'> {
  modalOpen: (model: ModelItem) => void;
}

const useModalModelDelete = ({ onClose }: Props = {}): ModalHooks => {
  const { modalOpen: openOrUpdate, ...modalHook } = useModal({ onClose });

  const { canDeleteModel } = usePermissions();

  const getModalProps = useCallback(
    (model: ModelItem): ModalFuncProps => {
      const handleOk = async () => {
        try {
          await deleteModel({ modelName: model.name });
          routeToReactUrl(paths.modelList());
        } catch (e) {
          handleError(e, {
            level: ErrorLevel.Error,
            publicMessage: 'Please try again later.',
            publicSubject: 'Unable to delete model.',
            silent: false,
            type: ErrorType.Server,
          });
        }
      };

      return canDeleteModel({ model })
        ? {
            closable: true,
            content: `
        Are you sure you want to delete this model "${model?.name}"
        and all of its versions from the model registry?
      `,
            icon: null,
            okButtonProps: { type: 'primary' },
            okText: 'Delete Model',
            okType: 'danger',
            onOk: handleOk,
            title: 'Confirm Delete',
          }
        : clone(CANNOT_DELETE_MODAL_PROPS);
    },
    [canDeleteModel],
  );

  const modalOpen = useCallback(
    (model: ModelItem) => {
      openOrUpdate(getModalProps(model));
    },
    [getModalProps, openOrUpdate],
  );

  return { modalOpen, ...modalHook };
};

export default useModalModelDelete;
