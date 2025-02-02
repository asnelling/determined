import { render, screen, waitFor } from '@testing-library/react';
import userEvent, { PointerEventsCheckLevel } from '@testing-library/user-event';
import React from 'react';

import ActionDropdown from 'shared/components/ActionDropdown/ActionDropdown';

const user = userEvent.setup({ pointerEventsCheck: PointerEventsCheckLevel.Never });

const ACTION_ONE_TEXT = 'Action One';
const ACTION_TWO_TEXT = 'Action Two';

enum TestAction {
  ActionOne = 'Action One',
  ActionTwo = 'Action Two',
}

const handleActionOne = jest.fn();
const handleActionTwo = jest.fn();

const DropDownContainer = () => {
  const dropDownOnTrigger = () => {
    return {
      [TestAction.ActionOne]: () => handleActionOne(),
      [TestAction.ActionTwo]: () => handleActionTwo(),
    };
  };

  return (
    <ActionDropdown<TestAction>
      actionOrder={[TestAction.ActionOne, TestAction.ActionTwo]}
      id={'test-id'}
      kind="test"
      onError={() => {
        return;
      }}
      onTrigger={dropDownOnTrigger()}
    />
  );
};

const setup = () => {
  const view = render(<DropDownContainer />);
  return { view };
};

describe('ActionDropdown', () => {
  setup();

  it('should display trigger button', () => {
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  it('should display actions', async () => {
    setup();

    user.click(screen.getByRole('button'));

    await waitFor(() => {
      expect(screen.getByText(ACTION_ONE_TEXT)).toBeInTheDocument();
      expect(screen.getByText(ACTION_TWO_TEXT)).toBeInTheDocument();
    });
  });

  it('should call dropdown option one function', async () => {
    setup();
    await user.click(screen.getByRole('button'));
    expect(handleActionOne).not.toHaveBeenCalled();
    await user.click(screen.getByText(ACTION_ONE_TEXT));
    expect(handleActionOne).toHaveBeenCalled();
  });

  it('should call dropdown option two function', async () => {
    setup();
    await user.click(screen.getByRole('button'));
    expect(handleActionTwo).not.toHaveBeenCalled();
    await user.click(screen.getByText(ACTION_TWO_TEXT));
    expect(handleActionTwo).toHaveBeenCalled();
  });
});
