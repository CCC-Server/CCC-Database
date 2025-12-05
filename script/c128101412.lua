--Armed Dragon Chaos
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz 소환
	c:EnableReviveLimit()
	-- 기본 Xyz 소환: 레벨 10 몬스터 3장
	Xyz.AddProcedure(c,nil,10,3)

	-- 보정 소환: 1턴에 1번, 자신 필드의 랭크 7 "Armed Dragon" 엑시즈 몬스터를 소재로 사용
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon)
	e0:SetOperation(s.xyzop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)

	--① 이 카드의 소재 수 × 500 ATK 상승
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	--② (속공 효과) 소재 1개 떼고 상대 필드 1장 제외, 몬스터면 그 ATK만큼 데미지 (1턴에 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCost(s.rmcost)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	e2:SetCountLimit(1,id) -- ★ ② 효과 카드명 1턴에 1번
	c:RegisterEffect(e2)

	--③ 엑시즈 소환된 이 카드가 상대에 의해 파괴되었을 때
	--   묘지의 "Armed Dragon" 1장을 소환 조건 무시하고 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--------------------------------
-- 보정 Xyz 소환 관련
--------------------------------
-- ⚠ 세트코드 주의:
-- 0x111 : "Armed Dragon" (사용 중인 DB에 맞춰 수정 가능)
function s.ovfilter(c,xc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsRank(7)
		and c:IsSetCard(0x111) and c:IsCanBeXyzMaterial(xc)
end

-- 보정 소환 조건: 1턴에 1번 + 자신 필드에 랭크 7 "Armed Dragon" Xyz 존재
function s.xyzcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- "Once per turn" 처리
	if Duel.GetFlagEffect(tp,id)~=0 then return false end
	return Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,0,1,nil,c)
end

-- 보정 소환 실행: 대상 선택 후 그 위에 이 카드 엑시즈 소환, 소재 승계
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil,c)
	local tc=g:GetFirst()
	if not tc then return end
	-- 기존 소재를 이 카드로 옮김
	local mg=tc:GetOverlayGroup()
	if #mg>0 then
		Duel.Overlay(c,mg)
	end
	-- 선택한 몬스터 자체를 이 카드의 소재로 함
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	-- 이 턴 동안 이 보정 소환은 1번만
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end

--------------------------------
-- ① ATK 상승
--------------------------------
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

--------------------------------
-- ② 제외 + 번 데미지
--------------------------------
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
	-- 데미지는 이후에, 몬스터였을 때만 계산
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)~=0 and tc:IsType(TYPE_MONSTER) then
		local atk=tc:GetAttack()
		if atk<0 then atk=0 end
		if atk>0 then
			Duel.Damage(1-tp,atk,REASON_EFFECT)
		end
	end
end

--------------------------------
-- ③ 파괴 시 "Armed Dragon" 특소
--------------------------------
-- 상대에 의해(전투/효과) 파괴 + 엑시즈 소환된 상태여야 함
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_XYZ)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		and c:GetReasonPlayer()==1-tp
end

function s.spfilter(c,e,tp)
	-- "Armed Dragon" 몬스터, 자신 제외, 소환 조건 무시 특소 가능
	return c:IsSetCard(0x111) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,true,POS_FACEUP)
	end
end
