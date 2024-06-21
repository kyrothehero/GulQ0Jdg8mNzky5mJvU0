--T-0 Redeployment
local T0_SETNAME = 0x69ac
local s,id=GetID()
function s.initial_effect(c)
    --Continuous spell activation (does nothing)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

    --If a "T-0" monster(s) is sent to your GY (except during the Damage Step): 
    --You can target 1 of those monsters; 
    --Special Summon it, but banish it when it leaves the field.
    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_CUSTOM+id)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.reborn_target)
	e1:SetOperation(s.reborn_operation)
	c:RegisterEffect(e1)
	local g=Group.CreateGroup()
	g:KeepAlive()
	e1:SetLabelObject(g)
    --Register cards sent to the GY
	local e69=Effect.CreateEffect(c)
	e69:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e69:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e69:SetCode(EVENT_TO_GRAVE)
	e69:SetRange(LOCATION_SZONE)
	e69:SetLabelObject(e1)
	e69:SetOperation(s.regop)
	c:RegisterEffect(e69)

    --If this card is sent to the GY by card effect: 
    --You can send 1 "T-0" card from your Deck to the GY.
    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(function(e) return e:GetHandler():IsReason(REASON_EFFECT) end)
	e2:SetTarget(s.mill_target)
	e2:SetOperation(s.mill_operation)
	c:RegisterEffect(e2)
end

function s.reborn_filter(c,e,tp)
	return c:IsMonster() and c:IsSetCard(T0_SETNAME) and c:IsControler(tp)
        and c:IsCanBeEffectTarget(e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.reborn_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=e:GetLabelObject():Filter(s.reborn_filter,nil,e,tp)
	if chkc then return g:IsContains(chkc) and s.reborn_filter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and #g>0 and Duel.GetCurrentPhase()~=PHASE_DAMAGE end
	local tc=nil
	if #g==1 then
		tc=g:GetFirst()
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		tc=g:Select(tp,1,1,nil):GetFirst()
	end
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,tp,0)
end
function s.reborn_operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		--Banish it when it leaves the field
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(3300)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		tc:RegisterEffect(e1,true)
	end
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local tg=eg:Filter(s.reborn_filter,nil,e,tp)
	if #tg>0 then
		for tc in tg:Iter() do
			tc:RegisterFlagEffect(id,RESET_CHAIN,0,1)
		end
		local g=e:GetLabelObject():GetLabelObject()
		if Duel.GetCurrentChain()==0 then g:Clear() end
		g:Merge(tg)
		g:Remove(function(c) return c:GetFlagEffect(id)==0 end,nil)
		e:GetLabelObject():SetLabelObject(g)
		Duel.RaiseSingleEvent(e:GetHandler(),EVENT_CUSTOM+id,e,0,tp,tp,0)
	end
end

function s.mill_filter(c)
    return c:IsSetCard(T0_SETNAME) and c:IsAbleToGrave()
end
function s.mill_target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.mill_filter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.mill_operation(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.mill_filter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end
