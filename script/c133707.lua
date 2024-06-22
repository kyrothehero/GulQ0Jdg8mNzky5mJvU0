--T-0 Reviver
local T0_SETNAME = 0x69ac
local s,id=GetID()
function s.initial_effect(c)
    --If your opponent Special Summons a monster(s) from the Extra Deck: You can discard this card; 
    --Special Summon 1 "T-0" monster from your GY, 
    --then you can add 1 "T-0" card from your GY to your hand.
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_HAND)
	--e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.discard_con)
    e1:SetCost(s.discard_cost)
	e1:SetTarget(s.discard_tg)
	e1:SetOperation(s.discard_op)
	c:RegisterEffect(e1)

    --If you control a "T-0" monster: 
    --You can Special Summon this card from your GY, but banish it when it leaves the field. 
    --You can only use this effect of "T-0 Reviver" once per turn.
    local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.reborn_con)
	e2:SetTarget(s.reborn_tg)
	e2:SetOperation(s.reborn_op)
	c:RegisterEffect(e2)
end

function s.discard_filter(c,tp)
	return c:IsSummonLocation(LOCATION_EXTRA) and not c:IsSummonPlayer(tp)
end
function s.discard_con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.discard_filter,1,nil,tp)
end
function s.discard_cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDiscardable() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.discard_ss_filter(c,e,tp)
	return c:IsSetCard(T0_SETNAME) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.discard_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.discard_ss_filter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.thfilter(c)
	return c:IsSetCard(T0_SETNAME) and c:IsAbleToHand()
end
function s.discard_op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.discard_ss_filter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
    local sg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,nil)
    if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        sg=sg:Select(tp,1,1,nil)
        Duel.BreakEffect()
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

    --Defining what to check
function s.reborn_filter(c)
    return c:IsFaceup() and c:IsSetCard(T0_SETNAME)
end
    --Check for "T-0" monster
function s.reborn_con(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.reborn_filter,tp,LOCATION_MZONE,0,1,nil)
end
    --Activation legality
function s.reborn_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
    --Special summon itself from GY
function s.reborn_op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
        --Banish it if it leaves the field
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(3300)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
        e1:SetValue(LOCATION_REMOVED)
        e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
        c:RegisterEffect(e1,true)
    end
end
