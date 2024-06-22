--T-0 Chainer
local T0_SETNAME = 0x69ac
local s,id=GetID()
function s.initial_effect(c)
    --When your opponent activates a card or effect the turn this card was Special Summoned (Quick Effect): 
    --You can negate the activation. You can only use this effect of "T-0 Chainer" once per turn.
    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negate_con)
	e1:SetTarget(s.negate_tg)
	e1:SetOperation(s.negate_op)
    --e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)

    --If this card is Normal Summoned: You can send 1 card from your hand to the GY, 
    --then add 1 "T-0" monster from your Deck to your hand.
    local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetTarget(s.add_tg)
	e2:SetOperation(s.add_op)
	c:RegisterEffect(e2)
end

function s.negate_con(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and ep==1-tp and Duel.IsChainNegatable(ev)
end
function s.negate_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negate_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end

function s.add_filter(c)
	return c:IsSetCard(T0_SETNAME) and c:IsMonster() and c:IsAbleToHand()
end
function s.add_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.add_filter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_HANDES,0,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.add_op(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local h=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,LOCATION_HAND,0,1,1,nil)
	if #h>0 then
		Duel.SendtoGrave(h,REASON_EFFECT)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.add_filter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.BreakEffect()
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end
