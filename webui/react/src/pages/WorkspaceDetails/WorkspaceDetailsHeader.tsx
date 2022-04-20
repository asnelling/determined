import { DownOutlined } from '@ant-design/icons';
import { Button, Dropdown, Menu, Space, Tooltip } from 'antd';
import React, { useCallback, useMemo } from 'react';

import Icon from 'components/Icon';
import InlineEditor from 'components/InlineEditor';
import useModalProjectCreate from 'hooks/useModal/Project/useModalProjectCreate';
import useModalWorkspaceDelete from 'hooks/useModal/Workspace/useModalWorkspaceDelete';
import { archiveWorkspace, unarchiveWorkspace } from 'services/api';
import { Workspace } from 'types';
import handleError from 'utils/error';

import css from './WorkspaceDetailsHeader.module.scss';

interface Props {
  fetchWorkspace?: () => void;
  workspace: Workspace;
}

const WorkspaceDetailsHeader: React.FC<Props> = ({ workspace, fetchWorkspace }: Props) => {
  const { modalOpen: openProjectCreate } = useModalProjectCreate({ workspaceId: workspace.id });
  const { modalOpen: openWorkspaceDelete } = useModalWorkspaceDelete({ workspace });

  const handleProjectCreateClick = useCallback(() => {
    openProjectCreate();
  }, [ openProjectCreate ]);

  const handleArchiveClick = useCallback(() => {
    if (workspace.archived) {
      try {
        unarchiveWorkspace({ id: workspace.id });
        fetchWorkspace?.();
      } catch (e) {
        handleError(e, { publicSubject: 'Unable to unarchive workspace.' });
      }
    } else {
      try {
        archiveWorkspace({ id: workspace.id });
        fetchWorkspace?.();
      } catch (e) {
        handleError(e, { publicSubject: 'Unable to archive workspace.' });
      }
    }
  }, [ fetchWorkspace, workspace.archived, workspace.id ]);

  const handleDeleteClick = useCallback(() => {
    openWorkspaceDelete();
  }, [ openWorkspaceDelete ]);

  const ActionMenu = useMemo(() => {
    return (
      <Menu>
        <Menu.Item onClick={handleArchiveClick}>
          {workspace.archived ? 'Unarchive' : 'Archive'}
        </Menu.Item>
        <Menu.Item danger onClick={handleDeleteClick}>Delete...</Menu.Item>
      </Menu>
    );
  }, [ handleArchiveClick, handleDeleteClick, workspace.archived ]);

  return (
    <div className={css.base}>
      <Space align="center">
        <div className={css.icon}>{workspace.name[0]}</div>
        <div className={css.nameRow}>
          <h1 className={css.name}>
            <InlineEditor disabled={workspace.immutable} maxLength={80} value={workspace.name} />
          </h1>
          {workspace.archived && (
            <Tooltip title="Archived">
              <div>
                <Icon name="archive" size="small" />
              </div>
            </Tooltip>
          )}
        </div>
        {!workspace.immutable && (
          <Dropdown arrow overlay={ActionMenu} trigger={[ 'click' ]}>
            <DownOutlined style={{ fontSize: 12 }} />
          </Dropdown>
        )}
      </Space>
      {!workspace.immutable &&
        <Button onClick={handleProjectCreateClick}>New Project</Button>}
    </div>
  );
};

export default WorkspaceDetailsHeader;
