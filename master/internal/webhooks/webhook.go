package webhooks

import (
	"fmt"

	"github.com/uptrace/bun"

	"github.com/determined-ai/determined/master/pkg/protoutils"
	"github.com/determined-ai/determined/proto/pkg/webhookv1"
)

// Webhooks is a slice of Webhook objects.
type Webhooks []Webhook

// Proto converts a slice of webhooks to its protobuf representation.
func (ws Webhooks) Proto() []*webhookv1.Webhook {
	out := make([]*webhookv1.Webhook, len(ws))
	for i, w := range ws {
		out[i] = w.Proto()
	}
	return out
}

// Webhook corresponds to a row in the "webhooks" DB table.
type Webhook struct {
	bun.BaseModel `bun:"table:webhooks"`

	ID  WebhookID `bun:"id,pk,autoincrement"`
	URL string    `bun:"url,notnull"`

	Triggers    Triggers    `bun:"rel:has-many,join:id=webhook_id"`
	WebhookType WebhookType `bun:"webhook_type,notnull"`
}

// WebhookFromProto returns a model Webhook from a proto definition.
func WebhookFromProto(w *webhookv1.Webhook) Webhook {
	return Webhook{
		URL:         w.Url,
		Triggers:    TriggersFromProto(w.Triggers),
		WebhookType: WebhookTypeFromProto(w.WebhookType),
	}
}

// Proto converts a webhook to its protobuf representation.
func (w *Webhook) Proto() *webhookv1.Webhook {
	return &webhookv1.Webhook{
		Id:          int32(w.ID),
		Url:         w.URL,
		Triggers:    w.Triggers.Proto(),
		WebhookType: w.WebhookType.Proto(),
	}
}

// WebhookID is the type for Webhook IDs.
type WebhookID int

// WebhookType is type for the WebhookType enum.
type WebhookType string

// Triggers is a slice of Trigger objects—primarily useful for its methods.
type Triggers []*Trigger

// TriggersFromProto returns a slice of model Triggers from a proto definition.
func TriggersFromProto(ts []*webhookv1.Trigger) Triggers {
	out := make(Triggers, len(ts))
	for i, t := range ts {
		out[i] = TriggerFromProto(t)
	}
	return out
}

// Proto converts a slice of triggers to its protobuf representation.
func (ts Triggers) Proto() []*webhookv1.Trigger {
	out := make([]*webhookv1.Trigger, len(ts))
	for i, t := range ts {
		out[i] = t.Proto()
	}
	return out
}

// Trigger corresponds to a row in the "webhook_triggers" DB table.
type Trigger struct {
	bun.BaseModel `bun:"table:webhook_triggers"`

	ID          TriggerID              `bun:"id,pk,autoincrement"`
	TriggerType TriggerType            `bun:"trigger_type,notnull"`
	Condition   map[string]interface{} `bun:"condition,notnull"`
	WebhookID   WebhookID              `bun:"webhook_id,notnull"`

	Webhook *Webhook `bun:"rel:belongs-to,join:webhook_id=id"`
}

// TriggerFromProto returns a Trigger from a proto definition.
func TriggerFromProto(t *webhookv1.Trigger) *Trigger {
	return &Trigger{
		TriggerType: TriggerTypeFromProto(t.TriggerType),
		Condition:   t.Condition.AsMap(),
	}
}

// Proto converts a Trigger to its protobuf representation.
func (t *Trigger) Proto() *webhookv1.Trigger {
	return &webhookv1.Trigger{
		Id:          int32(t.ID),
		TriggerType: t.TriggerType.Proto(),
		Condition:   protoutils.ToStruct(t.Condition),
		WebhookId:   int32(t.WebhookID),
	}
}

// TriggerID is the type for Trigger IDs.
type TriggerID int

// TriggerType is type for the TriggerType enum.
type TriggerType string

const (
	// TriggerTypeStateChange represents a change in experiment state.
	TriggerTypeStateChange TriggerType = "EXPERIMENT_STATE_CHANGE"

	// TriggerTypeMetricThresholdExceeded represents a threshold for a training metric value.
	TriggerTypeMetricThresholdExceeded TriggerType = "METRIC_THRESHOLD_EXCEEDED"
)

const (
	// WebhookTypeDefault represents a default webhook.
	WebhookTypeDefault WebhookType = "DEFAULT"

	// WebhookTypeSlack represents a slack webhook.
	WebhookTypeSlack WebhookType = "SLACK"
)

// WebhookTypeFromProto returns a WebhookType from a proto.
func WebhookTypeFromProto(w webhookv1.WebhookType) WebhookType {
	switch w {
	case webhookv1.WebhookType_WEBHOOK_TYPE_DEFAULT:
		return WebhookTypeDefault
	case webhookv1.WebhookType_WEBHOOK_TYPE_SLACK:
		return WebhookTypeSlack
	default:
		// TODO(???): prob don't panic
		panic(fmt.Errorf("missing mapping for webhook type %s to SQL", w))
	}
}

// TriggerTypeFromProto returns a TriggerType from a proto.
func TriggerTypeFromProto(t webhookv1.TriggerType) TriggerType {
	switch t {
	case webhookv1.TriggerType_TRIGGER_TYPE_METRIC_THRESHOLD_EXCEEDED:
		return TriggerTypeMetricThresholdExceeded
	case webhookv1.TriggerType_TRIGGER_TYPE_EXPERIMENT_STATE_CHANGE:
		return TriggerTypeStateChange
	default:
		// TODO(???): prob don't panic
		panic(fmt.Errorf("missing mapping for trigger %s to SQL", t))
	}
}

// Proto returns a proto from a WebhookType.
func (w WebhookType) Proto() webhookv1.WebhookType {
	switch w {
	case WebhookTypeDefault:
		return webhookv1.WebhookType_WEBHOOK_TYPE_DEFAULT
	case WebhookTypeSlack:
		return webhookv1.WebhookType_WEBHOOK_TYPE_SLACK
	default:
		return webhookv1.WebhookType_WEBHOOK_TYPE_UNSPECIFIED
	}
}

// Proto returns a proto from a TriggerType.
func (t TriggerType) Proto() webhookv1.TriggerType {
	switch t {
	case TriggerTypeStateChange:
		return webhookv1.TriggerType_TRIGGER_TYPE_EXPERIMENT_STATE_CHANGE
	case TriggerTypeMetricThresholdExceeded:
		return webhookv1.TriggerType_TRIGGER_TYPE_METRIC_THRESHOLD_EXCEEDED
	default:
		return webhookv1.TriggerType_TRIGGER_TYPE_UNSPECIFIED
	}
}
