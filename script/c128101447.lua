--종이 비행기 - 합체로봇 종이킹
--Paper Plane - Combination Robot Paper King
local s,id=GetID()
function s.initial_effect(c)
	-- 기본 정보
	c:EnableReviveLimit()
	-- 융합 소재 : "Paper Plane" 몬스터 4장
	Fusion.AddProcMixRep(c,true,true,s.fusmat,4,4)

	s.listed_series={0xc53}

	--------------------------------
	-- (1) 융합 소환 성공시, 필드의 몬스터 최대 3장을 이 카드에 장착
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.eqcon1)
	e1:SetCountLimit(1,{id,0}) -- (1) 효과 하드 OPT
	e1:SetTarget(s.eqtg1)
	e1:SetOperation(s.eqop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- (2) 카드/효과 발동시, 장착 마법 1장 코스트로 발동 무효 + 파괴
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCountLimit(1,{id,1}) -- (2) 효과 하드 OPT
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--------------------------------
	-- (3) 퀵 : 이 카드를 제외하고, GY의 "Paper Plane" 몬스터 1장 특수 소환
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2}) -- (3) 효과 하드 OPT
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg3)
	e3:SetOperation(s.spop3)
	c:RegisterEffect(e3)
end

--------------------------------
-- 융합 소재 : "Paper Plane" 몬스터
--------------------------------
function s.fusmat(c,fc,sumtype,tp)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER)
end

--------------------------------
-- (1) 융합 소환 성공시 장착
--------------------------------
function s.eqcon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.eqfilter1(c,e,ec)
	-- 필드 위의 앞면 몬스터, 토큰/자신 제외
	return c:IsFaceup() and c:IsType(TYPE_MONSTER)
		and c~=ec and not c:IsType(TYPE_TOKEN)
		and not c:IsForbidden()
		and c:IsOnField() and c:IsCanBeEffectTarget(e)
end
function s.eqtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return false end
		return Duel.IsExistingMatchingCard(s.eqfilter1,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c,e,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,0,LOCATION_ONFIELD)
end
function s.equip_to(c,tp,tc)
	-- tc를 c에 장착 및 타입 변경 + 장착 제한 부여
	if not Duel.Equip(tp,tc,c,true) then return end
	-- 장착 마법 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_TYPE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
	e0:SetValue(TYPE_SPELL+TYPE_EQUIP)
	tc:RegisterEffect(e0)
	-- 이 카드에만 장착 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(function(e,cc) return cc==e:GetLabelObject() end)
	e1:SetLabelObject(c)
	tc:RegisterEffect(e1)
end
function s.eqop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and c:IsFaceup()) then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	if ft<=0 then return end
	local g=Duel.GetMatchingGroup(s.eqfilter1,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c,e,c)
	if #g==0 then return end
	local max=math.min(3,ft,#g)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local sg=g:Select(tp,1,max,nil)
	local tc=sg:GetFirst()
	while tc do
		s.equip_to(c,tp,tc)
		tc=sg:GetNext()
	end
end

--------------------------------
-- (2) 발동 무효 + 파괴
--------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainNegatable(ev)
end
function s.eqcfilter(c)
	return c:IsType(TYPE_EQUIP) and c:IsAbleToGraveAsCost()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=c:GetEquipGroup():Filter(s.eqcfilter,nil)
	if chk==0 then return #g>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg=g:Select(tp,1,1,nil)
	Duel.SendtoGrave(sg,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=re:GetHandler()
	local g=Group.FromCards(rc)
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if rc:IsRelateToEffect(re) and rc:IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		Duel.Destroy(rc,REASON_EFFECT)
	end
end

--------------------------------
-- (3) 이 카드를 제외하고, GY의 "Paper Plane" 몬스터 1장 특수 소환
--------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end
function s.spfilter3(c,e,tp)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp)
			and s.spfilter3(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter3,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter3,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
